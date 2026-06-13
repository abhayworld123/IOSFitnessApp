import SwiftUI

struct BasicVitalsOnboardingView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Binding var basicDetails: BasicDetailsData
    let onBack: () -> Void
    let onNext: () -> Void
    let currentPage: Int
    let totalPages: Int
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable {
        case age, weight, height
    }
    
    @State private var ageText = ""
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var weightUnitSel: WeightUnit = .kg
    @State private var heightUnitSel: HeightUnit = .cm
    @State private var heightCm: Double = 170
    
    private let ageRange = 5...100
    private let heightCmRange: ClosedRange<Double> = 100...220
    
    private let orange = Color(hex: "#D89644")
    private let titleColor = Color(hex: "#2C2C2E")
    private let mutedColor = Color(hex: "#A8A8A8")
    
    private var parsedAge: Int? {
        guard let v = Int(ageText.filter(\.isNumber)), ageRange.contains(v) else { return nil }
        return v
    }
    
    private var parsedWeightKg: Double? {
        guard let w = Double(weightText.filter(\.isNumber)), weightUnitSel.range.contains(w) else { return nil }
        return weightUnitSel.convert(w, to: .kg)
    }
    
    private var parsedHeightCm: Double? {
        guard let cm = heightUnitSel.parseHeight(heightText),
              heightCmRange.contains(cm) else { return nil }
        return cm
    }
    
    private var canContinue: Bool {
        parsedAge != nil && parsedWeightKg != nil && parsedHeightCm != nil
    }
    
    private var weightUnitSuffix: String {
        weightUnitSel == .kg ? "kg" : "lbs"
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic details")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(titleColor)
                            
                            Text("Let's gather your vitals to personalize your plan.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(mutedColor)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        vitalRow(
                            title: "How old are you?",
                            trailingAccessory: EmptyView()
                        ) {
                            underlinedField(
                                text: $ageText,
                                field: .age,
                                keyboard: .numberPad,
                                filter: { $0.filter(\.isNumber) }
                            )
                            Text("years old")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(mutedColor)
                        }
                        
                        vitalRow(
                            title: "What's your weight?",
                            trailingAccessory: dualSegment(
                                options: [(WeightUnit.kg, "KG"), (WeightUnit.lbs, "LBS")],
                                selection: $weightUnitSel
                            )
                        ) {
                            underlinedField(
                                text: $weightText,
                                field: .weight,
                                keyboard: .numberPad,
                                filter: { $0.filter(\.isNumber) }
                            )
                            Text(weightUnitSuffix)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(mutedColor)
                        }
                        
                        vitalRow(
                            title: "How tall are you?",
                            trailingAccessory: dualSegment(
                                options: [(HeightUnit.cm, "CM"), (HeightUnit.ftIn, "FT")],
                                selection: $heightUnitSel
                            )
                        ) {
                            underlinedField(
                                text: $heightText,
                                field: .height,
                                keyboard: heightUnitSel == .cm ? .numberPad : .default,
                                filter: heightFilter
                            )
                            if heightUnitSel == .cm {
                                Text("cm")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(mutedColor)
                            }
                        }
                        
                        tipCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                
                Spacer(minLength: 0)
                
                VStack(spacing: 16) {
                    Button(action: saveAndNext) {
                        Text("Save & Next")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(canContinue ? orange : Color(hex: "#E0E0E0"))
                            .cornerRadius(20)
                    }
                    .disabled(!canContinue)
                    .padding(.horizontal, 30)
                    
                    PageIndicatorView(currentPage: currentPage, totalPages: totalPages)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear(perform: hydrateFromBasicDetails)
        .onChange(of: weightUnitSel) { oldUnit, newUnit in
            guard oldUnit != newUnit else { return }
            if let w = Double(weightText.filter(\.isNumber)), oldUnit.range.contains(w) {
                let kg = oldUnit.convert(w, to: .kg)
                let displayed = WeightUnit.kg.convert(kg, to: newUnit)
                weightText = "\(Int(round(displayed)))"
            } else if let wKg = basicDetails.weight {
                let displayed = WeightUnit.kg.convert(wKg, to: newUnit)
                weightText = "\(Int(round(displayed)))"
            } else {
                weightText = "\(Int(round(newUnit.defaultValue)))"
            }
        }
        .onChange(of: heightUnitSel) { _, newUnit in
            heightText = newUnit.formatHeight(heightCm)
        }
    }
    
    private var headerBar: some View {
        HStack {
            Button(action: {
                HapticFeedback.impact(style: .light)
                onBack()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 17))
                }
                .foregroundColor(Color(hex: "#1C1C1E"))
            }
            
            Spacer()
            
            profileAvatar
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 12)
    }
    
    @ViewBuilder
    private var profileAvatar: some View {
        let name = authViewModel.currentUser?.name ?? ""
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
            
            if let initials = optionalInitials(from: name), !initials.isEmpty {
                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(titleColor)
            } else {
                Image("profilecircle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
    }
    
    private func optionalInitials(from name: String) -> String? {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        let chars = parts.prefix(2).compactMap { $0.first }
        let s = String(chars).uppercased()
        return s.isEmpty ? nil : s
    }
    
    private func vitalRow<A: View, C: View>(
        title: String,
        trailingAccessory: A,
        @ViewBuilder valueRow: () -> C
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(titleColor)
                Spacer(minLength: 8)
                trailingAccessory
            }
            
            HStack(alignment: .bottom, spacing: 10) {
                valueRow()
                Spacer(minLength: 0)
            }
        }
    }
    
    private func underlinedField(
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType,
        filter: @escaping (String) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("", text: text)
                .focused($focusedField, equals: field)
                .keyboardType(keyboard)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(orange)
                .multilineTextAlignment(.leading)
                .onChange(of: text.wrappedValue) { _, newValue in
                    let next = filter(newValue)
                    if next != newValue {
                        text.wrappedValue = next
                        return
                    }
                    if field == .height, let cm = heightUnitSel.parseHeight(next) {
                        heightCm = min(heightCmRange.upperBound, max(heightCmRange.lowerBound, cm))
                    }
                }
            
            Rectangle()
                .fill(Color(hex: "#2C2C2E"))
                .frame(height: 2)
                .frame(maxWidth: .infinity)
                .frame(minWidth: 120)
        }
    }
    
    private func heightFilter(_ raw: String) -> String {
        if heightUnitSel == .cm {
            return raw.filter(\.isNumber)
        }
        return raw.filter { $0.isNumber || $0 == "'" || $0 == "\"" || $0 == " " }
    }
    
    private func dualSegment<T: Hashable>(
        options: [(T, String)],
        selection: Binding<T>
    ) -> some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.0) { pair in
                let isOn = selection.wrappedValue == pair.0
                Button(action: {
                    HapticFeedback.impact(style: .light)
                    selection.wrappedValue = pair.0
                }) {
                    Text(pair.1)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isOn ? Color.white : mutedColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(isOn ? Color(hex: "#1C1C1E") : Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            Capsule().stroke(Color(hex: "#E5E5EA"), lineWidth: 1)
        )
    }
    
    private var tipCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#7C3AED"))
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text("Accurate data helps us build your perfect routine.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "#5B21B6"))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(hex: "#EDE9FE"))
        .cornerRadius(16)
    }
    
    private func hydrateFromBasicDetails() {
        weightUnitSel = basicDetails.weightUnit
        heightUnitSel = basicDetails.heightUnit
        
        if let a = basicDetails.age {
            ageText = "\(a)"
        }
        
        if let wKg = basicDetails.weight {
            let display = WeightUnit.kg.convert(wKg, to: weightUnitSel)
            weightText = "\(Int(round(display)))"
        } else {
            weightText = "\(Int(round(weightUnitSel.defaultValue)))"
        }
        
        if let h = basicDetails.height {
            heightCm = h
        }
        heightText = heightUnitSel.formatHeight(heightCm)
    }
    
    private func saveAndNext() {
        guard let age = parsedAge,
              let wKg = parsedWeightKg,
              let cm = parsedHeightCm else { return }
        
        basicDetails.age = age
        basicDetails.weight = wKg
        basicDetails.weightUnit = weightUnitSel
        basicDetails.height = cm
        basicDetails.heightUnit = heightUnitSel
        
        HapticFeedback.impact()
        onNext()
    }
}

#Preview {
    BasicVitalsOnboardingView(
        basicDetails: .constant(BasicDetailsData()),
        onBack: {},
        onNext: {},
        currentPage: 2,
        totalPages: OnboardingStep.count
    )
    .environmentObject(AuthViewModel())
}
