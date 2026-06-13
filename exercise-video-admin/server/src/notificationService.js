import { firestore, fv } from './firebase.js';

const USERS = 'users';
const NOTIFICATIONS = 'notifications';
const SETTINGS = 'settings';

function firstName(name = '') {
  const trimmed = String(name).trim();
  if (!trimmed) return 'there';
  return trimmed.split(/\s+/)[0] || trimmed;
}

function dayKey(date = new Date()) {
  return date.toISOString().slice(0, 10);
}

function copyForScenario(scenario, { name, streakDays = 0, inactiveDays = 0, workoutTitle = '' }) {
  const first = firstName(name);
  switch (scenario) {
    case 'missed_workout':
      if (workoutTitle) {
        return {
          title: `${first}, you planned ${workoutTitle} today`,
          message: 'Log a session or reschedule — consistency builds results.',
        };
      }
      return {
        title: `${first}, your workout is still waiting`,
        message: 'You planned to train today. Tap to log a session or pick a workout.',
      };
    case 'streak_at_risk':
      return {
        title: `Don't lose your ${streakDays}-day streak`,
        message: `${first}, a short session tonight keeps your momentum going.`,
      };
    case 'inactive':
      return {
        title: `We miss you, ${first}`,
        message: `It's been ${inactiveDays} days — pick up where you left off with a quick workout.`,
      };
    case 'new_build':
      return {
        title: 'Trakkit update available',
        message: 'New features and improvements are ready. Update to get the latest experience.',
      };
    default:
      return { title: 'Trakkit', message: 'You have a new notification.' };
  }
}

export async function createInboxIfAbsent(db, userId, {
  scenarioKey,
  type = 'system',
  title,
  message,
  actionURL = 'trakkit://dashboard',
}) {
  const ref = db.collection(USERS).doc(userId).collection(NOTIFICATIONS).doc(scenarioKey);
  const snap = await ref.get();
  if (snap.exists) return false;

  await ref.set({
    id: scenarioKey,
    type,
    title,
    message,
    timestamp: fv().serverTimestamp(),
    isRead: false,
    actionURL,
    scenarioKey,
  });
  return true;
}

export async function sendPushToUser(db, userId, { title, message, actionURL }) {
  const userDoc = await db.collection(USERS).doc(userId).get();
  const tokens = userDoc.data()?.fcmTokens || [];
  if (!tokens.length) return { sent: 0 };

  const messaging = (await import('firebase-admin')).default.messaging();
  const payload = {
    notification: { title, body: message },
    data: { actionURL: actionURL || 'trakkit://dashboard' },
  };

  let sent = 0;
  for (const token of tokens) {
    try {
      await messaging.send({ token, ...payload });
      sent += 1;
    } catch (err) {
      if (err?.code === 'messaging/registration-token-not-registered') {
        await db.collection(USERS).doc(userId).update({
          fcmTokens: fv().arrayRemove(token),
        });
      }
    }
  }
  return { sent };
}

export async function notifyUser(db, userId, opts) {
  const created = await createInboxIfAbsent(db, userId, opts);
  const prefsSnap = await db
    .collection(USERS)
    .doc(userId)
    .collection(SETTINGS)
    .doc('notifications')
    .get();
  const prefs = prefsSnap.data() || {};
  if (prefs.pushNotifications === false) return { created, push: { sent: 0 } };

  const push = await sendPushToUser(db, userId, {
    title: opts.title,
    message: opts.message,
    actionURL: opts.actionURL,
  });
  return { created, push };
}

/**
 * Daily cron: inactive users (3+ days), streak-at-risk, missed workout nudges.
 * Server-side complement to client-side NotificationTriggerService.
 */
export async function runDailyNotificationCron() {
  const db = firestore();
  const now = new Date();
  const threeDaysAgo = new Date(now.getTime() - 3 * 24 * 60 * 60 * 1000);

  const usersSnap = await db.collection(USERS).limit(500).get();
  let processed = 0;

  for (const userDoc of usersSnap.docs) {
    const userId = userDoc.id;
    const user = userDoc.data();
    const lastActive = user.lastActiveAt?.toDate?.();
    if (!lastActive) continue;

    const prefsSnap = await db
      .collection(USERS)
      .doc(userId)
      .collection(SETTINGS)
      .doc('notifications')
      .get();
    const prefs = prefsSnap.data() || {};

    if (lastActive < threeDaysAgo && prefs.workoutReminders !== false) {
      const inactiveDays = Math.floor((now - lastActive) / (24 * 60 * 60 * 1000));
      const copy = copyForScenario('inactive', { name: user.name, inactiveDays });
      await notifyUser(db, userId, {
        scenarioKey: `inactive_${inactiveDays}d`,
        type: 'system',
        title: copy.title,
        message: copy.message,
        actionURL: 'trakkit://dashboard',
      });
    }

    if (prefs.streakReminders !== false && (user.currentStreak || 0) >= 2) {
      const copy = copyForScenario('streak_at_risk', {
        name: user.name,
        streakDays: user.currentStreak || 0,
      });
      await notifyUser(db, userId, {
        scenarioKey: `streak_at_risk_${dayKey(now)}`,
        type: 'reminder',
        title: copy.title,
        message: copy.message,
        actionURL: 'trakkit://dashboard',
      });
    }

    processed += 1;
  }

  return { processed, at: now.toISOString() };
}

/**
 * Admin broadcast for new app builds / feature announcements.
 */
export async function broadcastSystemNotification(db, { title, message, actionURL = 'trakkit://dashboard' }) {
  const usersSnap = await db.collection(USERS).limit(500).get();
  const scenarioKey = `system_build_${dayKey()}`;
  let count = 0;

  for (const userDoc of usersSnap.docs) {
    const prefsSnap = await userDoc.ref.collection(SETTINGS).doc('notifications').get();
    const prefs = prefsSnap.data() || {};
    if (prefs.marketingNotifications === false) continue;

    await notifyUser(db, userDoc.id, {
      scenarioKey,
      type: 'system',
      title,
      message,
      actionURL,
    });
    count += 1;
  }

  return { count, scenarioKey };
}
