
import SwiftUI
import ComposableArchitecture
import SafariServices

// MARK: - Collapsible Ingredient Sections
struct CollapsibleIngredientSections: View {
    @Bindable var store: StoreOf<ProductDetailFeatureDomain>
    
    var body: some View {
        guard let assessment = store.healthAssessment else {
            return AnyView(
                Text("No ingredient analysis available")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            )
        }
        
        let allCitations = assessment.citations ?? []
        return AnyView(
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                Text("Ingredients Analysis")
                    .font(DesignSystem.Typography.heading2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            
            VStack(spacing: DesignSystem.Spacing.base) {
                if let highRisk = assessment.highRisk, !highRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "high-risk",
                        title: "High Risk",
                        ingredients: highRisk,
                        color: DesignSystem.Colors.primaryRed,
                        isExpanded: store.expandedSections.contains("high-risk"),
                        onToggle: { store.send(.toggleIngredientSection("high-risk")) },
                        onIngredientTap: { ingredient in
                            let resolvedCitations = ingredient.resolvedCitations(from: allCitations)
                            let fallback = resolvedCitations.isEmpty ? allCitations : resolvedCitations
                            store.send(.ingredientTappedWithCitations(ingredient, fallback))
                        }
                    )
                }
                
                if let moderateRisk = assessment.moderateRisk, !moderateRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "moderate-risk",
                        title: "Moderate Risk",
                        ingredients: moderateRisk,
                        color: DesignSystem.Colors.warning,
                        isExpanded: store.expandedSections.contains("moderate-risk"),
                        onToggle: { store.send(.toggleIngredientSection("moderate-risk")) },
                        onIngredientTap: { ingredient in
                            let resolvedCitations = ingredient.resolvedCitations(from: allCitations)
                            let fallback = resolvedCitations.isEmpty ? allCitations : resolvedCitations
                            store.send(.ingredientTappedWithCitations(ingredient, fallback))
                        }
                    )
                }
                
                if let lowRisk = assessment.lowRisk, !lowRisk.isEmpty {
                    CollapsibleIngredientSection(
                        sectionId: "low-risk",
                        title: "Low Risk",
                        ingredients: lowRisk,
                        color: DesignSystem.Colors.success,
                        isExpanded: store.expandedSections.contains("low-risk"),
                        onToggle: { store.send(.toggleIngredientSection("low-risk")) },
                        onIngredientTap: { ingredient in
                            let resolvedCitations = ingredient.resolvedCitations(from: allCitations)
                            let fallback = resolvedCitations.isEmpty ? allCitations : resolvedCitations
                            store.send(.ingredientTappedWithCitations(ingredient, fallback))
                        }
                    )
                }
                
                if (assessment.highRisk?.isEmpty ?? true) &&
                   (assessment.moderateRisk?.isEmpty ?? true) &&
                   (assessment.lowRisk?.isEmpty ?? true) {
                    Text("Ingredient analysis not available for this product")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
                }
                }
                .padding(.horizontal, DesignSystem.Spacing.screenPadding)
            }
        )
    }
}

// MARK: - Collapsible Ingredient Section
struct CollapsibleIngredientSection: View {
    let sectionId: String
    let title: String
    let ingredients: [IngredientRisk]
    let color: Color
    let isExpanded: Bool
    let onToggle: () -> Void
    let onIngredientTap: (IngredientRisk) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.base) {
            Button(action: onToggle) {
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                    
                    Text("\(title) (\(ingredients.count))")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(.vertical, DesignSystem.Spacing.base)
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.backgroundSecondary)
                .cornerRadius(DesignSystem.CornerRadius.md)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: DesignSystem.Spacing.sm)
                ], spacing: DesignSystem.Spacing.sm) {
                    ForEach(ingredients, id: \.name) { ingredient in
                        CollapsibleIngredientPill(
                            ingredient: ingredient,
                            color: color,
                            onTap: { onIngredientTap(ingredient) }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, DesignSystem.Spacing.md)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
        .background(DesignSystem.Colors.background)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .shadow(
            color: DesignSystem.Shadow.light,
            radius: DesignSystem.Shadow.radiusLight,
            x: 0,
            y: DesignSystem.Shadow.offsetLight.height
        )
    }
}

// MARK: - Collapsible Ingredient Pill
struct CollapsibleIngredientPill: View {
    let ingredient: IngredientRisk
    let color: Color
    let onTap: () -> Void
    
    var ingredientColor: Color {
        let baseColor = color // Category color (red/yellow/green)
        let hash = abs(ingredient.name.hashValue)
        
        let hueShift = Double((hash % 30) - 15) / 360.0
        
        let saturationMultiplier = 0.7 + (Double(hash % 20) / 100.0)
        
        let brightnessMultiplier = 0.6 + (Double(hash % 20) / 100.0)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var opacity: CGFloat = 0
        
        UIColor(baseColor).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &opacity)
        
        hue += CGFloat(hueShift)
        saturation *= CGFloat(saturationMultiplier)
        brightness *= CGFloat(brightnessMultiplier)
        
        hue = max(0, min(1, hue))
        saturation = max(0, min(1, saturation))
        brightness = max(0, min(1, brightness))
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: opacity))
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(ingredient.name)
                .font(DesignSystem.Typography.small)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            ingredientColor,
                            ingredientColor.opacity(0.85)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(DesignSystem.CornerRadius.md)
                .shadow(color: ingredientColor.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Ingredient Detail Sheet
struct EnhancedIngredientDetailSheet: View {
    let ingredient: IngredientRisk
    let citations: [Citation]
    @Environment(\.dismiss) private var dismiss
    
    private var riskColor: Color {
        switch ingredient.riskLevel?.lowercased() {
        case "high": return DesignSystem.Colors.primaryRed
        case "moderate": return DesignSystem.Colors.warning
        case "low": return DesignSystem.Colors.success
        default: return DesignSystem.Colors.textSecondary
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text(ingredient.name)
                            .font(DesignSystem.Typography.heading1)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let riskLevel = ingredient.riskLevel {
                            HStack {
                                Circle()
                                    .fill(riskColor)
                                    .frame(width: 8, height: 8)
                                
                                Text("\(riskLevel.capitalized) Risk")
                                    .font(DesignSystem.Typography.bodyMedium)
                                    .foregroundColor(riskColor)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.base)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(riskColor.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.full)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Analysis")
                            .font(DesignSystem.Typography.heading3)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text(cleanAnalysisText(ingredient.overview ?? ingredient.microReport))
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        if !citations.isEmpty {
                            Text("Citations")
                                .font(DesignSystem.Typography.heading3)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            VStack(spacing: DesignSystem.Spacing.sm) {
                                ForEach(citations.prefix(3), id: \.id) { citation in
                                    CitationCard(citation: citation) {
                                        if let urlString = citation.url,
                                           let url = URL(string: urlString),
                                           MedicalAuthorityMapper.isValidMedicalURL(urlString) {
                                        }
                                    }
                                }
                            }
                            
                            if citations.count > 3 {
                                Text("+ \(citations.count - 3) more references")
                                    .font(DesignSystem.Typography.small)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.top, DesignSystem.Spacing.xs)
                            }
                            
                            AIDisclaimerCard()
                                .padding(.top)
                        } else {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(DesignSystem.Typography.small)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                    
                                    Text("Health Information Disclaimer")
                                        .font(DesignSystem.Typography.small)
                                        .fontWeight(.semibold)
                                        .foregroundColor(DesignSystem.Colors.primaryRed)
                                }
                                
                                Text("This analysis is AI-generated based on ingredient databases and nutritional research. Always consult healthcare professionals for medical advice.")
                                    .font(DesignSystem.Typography.small)
                                    .foregroundColor(DesignSystem.Colors.primaryRed.opacity(0.9))
                                    .lineSpacing(2)
                            }
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.primaryRed.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(DesignSystem.CornerRadius.md)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.base)
            }
            .background(DesignSystem.Colors.background)
            .navigationTitle("Ingredient Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                }
            }
        }
    }
}

// MARK: - Medical Authority Mapper
struct MedicalAuthorityMapper {
    private static let medicalAuthorities: [String: String] = [
        "fda.gov": "U.S. Food & Drug Administration",
        "nih.gov": "National Institutes of Health",
        "cdc.gov": "Centers for Disease Control and Prevention",
        "usda.gov": "U.S. Department of Agriculture",
        "who.int": "World Health Organization",
        
        "mayoclinic.org": "Mayo Clinic",
        "heart.org": "American Heart Association",
        "cancer.org": "American Cancer Society",
        "diabetes.org": "American Diabetes Association",
        "kidney.org": "National Kidney Foundation",
        "lung.org": "American Lung Association",
        
        "harvard.edu": "Harvard Medical School",
        "johnshopkins.edu": "Johns Hopkins Medicine",
        "stanford.edu": "Stanford Medicine",
        "ucsf.edu": "UC San Francisco",
        "mountsinai.org": "Mount Sinai Health System",
        "clevelandclinic.org": "Cleveland Clinic",
        
        "pcrm.org": "Physicians Committee for Responsible Medicine",
        "nutrition.org": "American Society for Nutrition",
        "acsh.org": "American Council on Science and Health",
        "hsph.harvard.edu": "Harvard T.H. Chan School of Public Health",
        "ncbi.nlm.nih.gov": "National Center for Biotechnology Information",
        "pubmed.ncbi.nlm.nih.gov": "PubMed - National Library of Medicine",
        "cochranelibrary.com": "Cochrane Library",
        "bmj.com": "BMJ (British Medical Journal)",
        "thelancet.com": "The Lancet",
        "nejm.org": "New England Journal of Medicine",
        
        "aicr.org": "American Institute for Cancer Research",
        "cancercouncil.com.au": "Cancer Council Australia",
        "cancerresearchuk.org": "Cancer Research UK",
        "diabetesjournals.org": "American Diabetes Association Journals",
        "healthline.com": "Healthline Medical Review Board",
        "medicalnewstoday.com": "Medical News Today",
        "webmd.com": "WebMD Medical Reference",
        "verywellhealth.com": "Verywell Health",
        "everydayhealth.com": "Everyday Health",
        "nutrition.gov": "Nutrition.gov",
        "foodsafety.gov": "FoodSafety.gov",
        "extension.org": "Extension Publications",
        "nutritionsource.hsph.harvard.edu": "Harvard Nutrition Source",
        "health.harvard.edu": "Harvard Health Publishing",
        "medlineplus.gov": "MedlinePlus"
    ]
    
    static func getAuthorityName(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return extractFallbackSource(from: urlString)
        }
        
        if let authority = medicalAuthorities[host] {
            return authority
        }
        
        for (domain, authority) in medicalAuthorities {
            if host.contains(domain) || domain.contains(host) {
                return authority
            }
        }
        
        return formatDomainName(host)
    }
    
    private static func extractFallbackSource(from urlString: String) -> String {
        let patterns = [
            "https?://(?:www\\.)?([^/]+)",
            "([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(location: 0, length: urlString.count)),
               let range = Range(match.range(at: 1), in: urlString) {
                let domain = String(urlString[range]).lowercased()
                return formatDomainName(domain)
            }
        }
        
        return "Medical Authority"
    }
    
    private static func formatDomainName(_ domain: String) -> String {
        let cleanDomain = domain.replacingOccurrences(of: "www.", with: "")
        let parts = cleanDomain.components(separatedBy: ".")
        
        if let mainPart = parts.first {
            let formatted = mainPart.prefix(1).capitalized + mainPart.dropFirst()
            
            switch formatted.lowercased() {
            case "pubmed": return "PubMed"
            case "ncbi": return "NCBI"
            case "webmd": return "WebMD"
            case "healthline": return "Healthline"
            case "medicalnewstoday": return "Medical News Today"
            default: return formatted
            }
        }
        
        return cleanDomain.capitalized
    }
    
    static func isValidMedicalURL(_ urlString: String?) -> Bool {
        guard let urlString = urlString,
              let url = URL(string: urlString),
              let scheme = url.scheme else {
            return false
        }
        
        guard scheme == "http" || scheme == "https" else {
            return false
        }
        
        guard let host = url.host, !host.isEmpty else {
            return false
        }
        
        return true
    }
}

// MARK: - Citation Card with Enhanced Medical Authority Display
struct CitationCard: View {
    let citation: Citation
    let onTap: (() -> Void)?
    @State private var showingSafari = false
    @State private var isPressed = false
    
    init(citation: Citation, onTap: (() -> Void)? = nil) {
        self.citation = citation
        self.onTap = onTap
    }
    
    var citationURL: URL? {
        guard let urlString = citation.url, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    var isGroundingRedirectURL: Bool {
        guard let urlString = citation.url else { return false }
        return urlString.contains("vertexaisearch.cloud.google.com") || 
               urlString.contains("grounding-api-redirect")
    }
    
    private var medicalAuthorityName: String {
        if let urlString = citation.url {
            return MedicalAuthorityMapper.getAuthorityName(from: urlString)
        }
        return citation.source
    }
    
    private var isValidURL: Bool {
        MedicalAuthorityMapper.isValidMedicalURL(citation.url)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(citation.title)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(medicalAuthorityName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .fontWeight(.medium)
                    
                    Text("(\(citation.year))")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                if isValidURL {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                        Text("Tap to read")
                            .font(DesignSystem.Typography.captionMedium)
                            .foregroundColor(DesignSystem.Colors.primaryRed)
                    }
                } else {
                    Image(systemName: "doc.text")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(isValidURL ? DesignSystem.Colors.primaryRed.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(
            color: DesignSystem.Shadow.medium,
            radius: DesignSystem.Shadow.radiusMedium,
            x: 0,
            y: DesignSystem.Shadow.offsetMedium.height
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .contentShape(Rectangle())
        .onTapGesture {
            guard isValidURL else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                
                if let onTap = onTap {
                    onTap()
                } else {
                    showingSafari = true
                }
            }
        }
        .safariView(isPresented: $showingSafari, url: citationURL)
    }
}

// MARK: - Legacy Ingredient Detail Sheet (for backward compatibility)
struct IngredientDetailSheet: View {
    let ingredient: IngredientRisk
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        EnhancedIngredientDetailSheet(ingredient: ingredient, citations: [])
    }
}

// MARK: - AI Disclaimer Card
struct AIDisclaimerCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(DesignSystem.Typography.small)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
                
                Text("AI-Generated Citations")
                    .font(DesignSystem.Typography.captionMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignSystem.Colors.primaryRed)
            }
            
            Text("These citations are AI-generated from reliable medical sources. Always consult healthcare professionals for medical advice.")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.primaryRed.opacity(0.9))
                .lineSpacing(2)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.primaryRed.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.primaryRed.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
    }
}

// MARK: - Helper Functions
private func cleanAnalysisText(_ text: String) -> String {
    var cleanedText = text
    
    cleanedText = cleanedText.replacingOccurrences(
        of: #"\(Sources?:\s*,+\s*\)"#,
        with: "",
        options: .regularExpression
    )
    
    cleanedText = cleanedText.replacingOccurrences(
        of: #"\(Sources?:[^)]*\)"#,
        with: "",
        options: .regularExpression
    )
    
    cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return cleanedText
}
