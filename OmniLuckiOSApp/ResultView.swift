import SwiftUI

struct ResultView: View {
    let percentage: Int
    let explanation: OmniLuckLogic.LuckExplanation
    var caption: String? = nil
    var summary: String? = nil // Why this score?

    
    // Computed property for caption with fallback to match Web App logic
    var displayCaption: String {
        if let c = caption, !c.isEmpty { return c }
        if percentage >= 80 { return "🚀 Cosmic Jackpot!" }
        else if percentage >= 60 { return "✨ Strong Vibes" }
        else if percentage >= 40 { return "⚖️ Balanced Energy" }
        else { return "🛡️ Stay Grounded" }
    }

    // Birth Info for fetching chart
    var birthInfo: (dob: Date, time: Date, place: String, timeIsNA: Bool)? = nil
    
    // NEW: Strategic Data
    var strategicAdvice: String? = nil
    var luckyTimeSlots: [String]? = nil
    
    @Environment(\.dismiss) var dismiss
    
    @State private var displayedPercentage = 0
    @State private var isAnimating = false
    @State private var showCard = false
    @State private var showReport = false
    @State private var isLuckCardExpanded = true  // Daily Luck Score card expanded by default
    
    // Forecast Data State
    @State private var forecastData: ForecastResponse? = nil
    @State private var isForecastFlipped = false  // For flip card animation
    
    // Modal States (popup overlays)
    @State private var showAnalysisModal = false
    @State private var showStrategyModal = false
    @State private var showPowerHoursModal = false
    @State private var showPowerballModal = false
    
    // Powerball Data
    var personalPowerball: PowerballNumbers? = nil
    var dailyPowerballs: [PowerballNumbers]? = nil
    
    // Chart Data State (Restored)
    @State private var chartData: NatalChartResponse? = nil
    @State private var isLoadingChart = false
    
    // Light Celestial Color Palette
    let accentPurple = Color(red: 0.75, green: 0.6, blue: 0.95)  // Light purple
    let accentGold = Color(red: 1.0, green: 0.9, blue: 0.5)      // Light yellow/gold
    let deepPurple = Color(red: 0.5, green: 0.3, blue: 0.7)      // Medium purple for text
    
    var luckColor: Color {
        if percentage >= 70 { return Color.green }
        else if percentage >= 40 { return accentGold }
        else { return Color.orange }
    }
    
    // Computed padding for Daily Luck Score card
    var cardPadding: EdgeInsets {
        isLuckCardExpanded ? EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16) 
                          : EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [
                    Color(red: 1.0, green: 0.98, blue: 0.9),
                    Color(red: 0.95, green: 0.9, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0)
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            // Decorative Glow
            Circle().fill(accentPurple.opacity(0.3)).frame(width: 300, height: 300).blur(radius: 80).offset(y: -100)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    // Prevent horizontal overflow
                
                // Daily Luck Score Card (Collapsible, Expanded by Default)
                VStack(alignment: .leading, spacing: 12) {
                    // Card Header
                    HStack {
                        HStack(spacing: 8) {
                            Text("🎯")
                                .font(.title3)
                            Text("Daily Luck Score")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                        }
                        
                        Spacer()
                        
                        Image(systemName: isLuckCardExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(accentPurple)
                            .rotationEffect(.degrees(isLuckCardExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isLuckCardExpanded)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isLuckCardExpanded.toggle()
                        }
                    }
                    
                    // Card Content
                    if isLuckCardExpanded {
                        VStack(spacing: 20) {
                            ZStack {
                                // Background Ring
                                Circle().stroke(accentPurple.opacity(0.2), lineWidth: 12).frame(width: 200, height: 200)
                                // Progress Ring
                                Circle()
                                    .trim(from: 0, to: isAnimating ? CGFloat(percentage) / 100.0 : 0)
                                    .stroke(
                                        AngularGradient(colors: [luckColor, luckColor.opacity(0.5), luckColor], center: .center),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 200, height: 200).rotationEffect(.degrees(-90))
                                    .animation(.easeOut(duration: 1.5), value: isAnimating)
                                
                                // Percentage Text
                                VStack(spacing: 5) {
                                    Text("\(displayedPercentage)")
                                        .font(.system(size: 72, weight: .bold, design: .rounded)).foregroundColor(deepPurple)
                                    Text("%").font(.title).fontWeight(.light).foregroundColor(deepPurple.opacity(0.7))
                                }
                            }
                            .shadow(color: luckColor.opacity(0.5), radius: 20, x: 0, y: 10)
                            
                            // Caption (Inside Card)
                            if showCard {
                                Text(displayCaption)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(accentPurple)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: isLuckCardExpanded ? 20 : 14)
                        .fill(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: isLuckCardExpanded ? 20 : 14)
                                .stroke(accentPurple.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.easeOut(duration: 0.5), value: isAnimating)
                .onAppear {
                    withAnimation { isAnimating = true }
                    // Counter animation
                    let steps = 60; let stepTime = 1.5 / Double(steps)
                    for i in 0...steps {
                        DispatchQueue.main.asyncAfter(deadline: .now() + (stepTime * Double(i))) {
                            self.displayedPercentage = Int(Double(self.percentage) * (Double(i) / Double(steps)))
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { showCard = true }
                    }
                    
                    // Fetch Forecast
                    if let info = birthInfo {
                        Task {
                            do {
                                let forecast = try await NetworkService.shared.fetchForecast(
                                    name: "User",
                                    dob: info.dob,
                                    birthTime: info.time,
                                    birthPlace: info.place,
                                    timeIsNA: info.timeIsNA
                                )
                                await MainActor.run { self.forecastData = forecast }
                            } catch {
                                print("Forecast Error: \(error)")
                            }
                        }
                    }
                }
                    
                    // SECTION 1: Daily Luck Analysis Button
                    Button(action: { showAnalysisModal = true }) {
                        HStack {
                            Text("📜").font(.title3)
                            Text("Read Daily Luck Analysis").font(.subheadline).fontWeight(.semibold).foregroundColor(deepPurple)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill").foregroundColor(accentPurple)
                        }
                        .padding(.vertical, 14).padding(.horizontal, 18)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentPurple.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                    // SECTION 2: Cosmic Strategy Button
                    if strategicAdvice != nil {
                        Button(action: { showStrategyModal = true }) {
                            HStack {
                                Text("🧭").font(.title3)
                                Text("Read Cosmic Strategy").font(.subheadline).fontWeight(.semibold).foregroundColor(deepPurple)
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill").foregroundColor(accentPurple)
                            }
                            .padding(.vertical, 14).padding(.horizontal, 18)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentPurple.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    // SECTION 3: Power Hours Button
                    if let slots = luckyTimeSlots, !slots.isEmpty {
                        Button(action: { showPowerHoursModal = true }) {
                            HStack {
                                Text("⏰").font(.title3)
                                Text("View Power Hours").font(.subheadline).fontWeight(.semibold).foregroundColor(deepPurple)
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill").foregroundColor(accentGold)
                            }
                            .padding(.vertical, 14).padding(.horizontal, 18)
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentGold.opacity(0.6), lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                    
                    // Daily Astro Insights Button
                    Button(action: {
                        // Fetch chart data when opening modal
                        Task {
                            if chartData == nil, let info = birthInfo {
                                isLoadingChart = true
                                do {
                                    chartData = try await NetworkService.shared.fetchNatalChart(
                                        dob: info.dob,
                                        birthTime: info.time,
                                        birthPlace: info.place,
                                        timeIsNA: info.timeIsNA
                                    )
                                } catch {
                                    print("Chart Error: \(error)")
                                }
                                isLoadingChart = false
                            }
                        }
                        showReport = true
                    }) {
                        HStack {
                            Text("🌟").font(.title3)
                            Text("Read Daily Astro Insights").font(.subheadline).fontWeight(.semibold).foregroundColor(deepPurple)
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill").foregroundColor(accentPurple)
                        }
                        .padding(.vertical, 14).padding(.horizontal, 18)
                        .background(Color.white.opacity(0.6))
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentPurple.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    
                // NEW: Powerball Section
                Button(action: { showPowerballModal = true }) {
                    HStack(spacing: 12) {
                        Text("🎱")
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lucky Powerball Numbers")
                                .font(.headline)
                                .foregroundColor(deepPurple)
                            Text("Astro-Numerology combinations")
                                .font(.caption)
                                .foregroundColor(deepPurple.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentPurple)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal)
                // Removed extra bottom padding, relying on VStack(spacing: 10)

                // 7-Day Forecast FLIP Card
                if let forecast = forecastData {
                    ZStack {
                        // BACK SIDE (The Chart)
                        VStack(alignment: .leading, spacing: 10) {
                            // Header with close hint
                            HStack {
                                Text("").font(.title3)
                                Text("7-Day Luck Trajectory").font(.headline).foregroundColor(deepPurple)
                                Spacer()
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .foregroundColor(accentPurple.opacity(0.6))
                            }
                            
                            // Trend and Peak Row
                            HStack {
                                Text("Trend:").font(.caption).foregroundColor(deepPurple.opacity(0.7))
                                Text(forecast.trend_direction).font(.caption).fontWeight(.bold).foregroundColor(accentPurple)
                                Spacer()
                                Text("Peak:").font(.caption).foregroundColor(deepPurple.opacity(0.7))
                                if let best = forecast.trajectory.max(by: { $0.luck_score < $1.luck_score }) {
                                    Text("\(formatDayMonth(best.date)) (\(best.luck_score)%)")
                                        .font(.caption).fontWeight(.bold).foregroundColor(accentPurple)
                                } else {
                                    Text(formatDayMonth(forecast.best_day)).font(.caption).fontWeight(.bold).foregroundColor(accentPurple)
                                }
                            }
                            
                            // Bar Chart
                            HStack(alignment: .bottom, spacing: 4) {
                                ForEach(forecast.trajectory) { day in
                                    VStack(spacing: 2) {
                                        Text("\(day.luck_score)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(deepPurple)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        day.luck_score >= 80 ? Color.green : (day.luck_score < 50 ? Color.orange : accentGold),
                                                        (day.luck_score >= 80 ? Color.green : (day.luck_score < 50 ? Color.orange : accentGold)).opacity(0.5)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(height: max(10, CGFloat(day.luck_score) * 0.7))
                                        
                                        Text(getDayName(day.date))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundColor(deepPurple.opacity(0.8))
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .frame(height: 90)
                            .clipped() // Prevent Horizontal Overflow from Chart
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.95))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentPurple.opacity(0.3), lineWidth: 1))
                        )
                        .rotation3DEffect(.degrees(isForecastFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                        .opacity(isForecastFlipped ? 1 : 0) // Hide when not flipped to prevent hit testing issues
                        
                        // FRONT SIDE (The Teaser)
                        VStack(spacing: 16) {
                            Text("🔮").font(.system(size: 44))
                            
                            Text("7-Day Cosmic Forecast")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(deepPurple)
                            
                            Text("Tap to reveal your luck trajectory")
                                .font(.subheadline)
                                .foregroundColor(deepPurple.opacity(0.7))
                            
                            HStack(spacing: 8) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundColor(accentPurple)
                                Text("Tap to flip")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(accentPurple)
                            }
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200) // Match height of back side approx
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(LinearGradient(colors: [Color.white.opacity(0.9), accentPurple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .overlay(RoundedRectangle(cornerRadius: 20).stroke(accentPurple.opacity(0.4), lineWidth: 1))
                        )
                        .rotation3DEffect(.degrees(isForecastFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        .opacity(isForecastFlipped ? 0 : 1)
                    }
                    .frame(height: 200) // Fixed height container
                    .padding(.horizontal)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isForecastFlipped.toggle()
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Home Button
                Button(action: { dismiss() }) {
                    HStack(spacing: 10) { Image(systemName: "house.fill"); Text("Home") }
                        .font(.headline).foregroundColor(deepPurple).padding(.vertical, 16).frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16).shadow(color: accentGold.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal).padding(.bottom, 60) // Increased bottom padding for safe scroll area
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width) // Hard constrain to screen width
            .clipped() // Prevent horizontal overflow
            .padding(.top, 20) // Add some top padding inside scroll
            .scrollBounceBehavior(.basedOnSize) // iOS 16.4+ only bounces when content overflows


        }
        .navigationBarBackButtonHidden(true)
        .preferredColorScheme(.light)
        // MODAL OVERLAYS
        .overlay(analysisModalOverlay)
        .overlay(strategyModalOverlay)
        .overlay(powerHoursModalOverlay)
        .overlay(astroInsightsModalOverlay)
        .overlay(powerballModalOverlay)
    }
    
    // MARK: - Analysis Modal
    @ViewBuilder
    private var analysisModalOverlay: some View {
        if showAnalysisModal {
            ZStack {
                // Dimmed Background (tap to dismiss)
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showAnalysisModal = false } }
                
                // Modal Card
                VStack(spacing: 0) {
                    // Header with X
                    HStack {
                        Text("📜 Daily Luck Analysis").font(.headline).foregroundColor(deepPurple)
                        Spacer()
                        Button(action: { withAnimation { showAnalysisModal = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundColor(accentPurple.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(accentPurple.opacity(0.1))
                    
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(explanation.text)
                                .font(.body)
                                .foregroundColor(deepPurple)
                                .lineSpacing(6)
                            
                            // Traits
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 85), spacing: 6)], spacing: 8) {
                                ForEach(explanation.traits, id: \.self) { trait in
                                    Text(trait)
                                        .font(.caption).fontWeight(.semibold)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Capsule().fill(accentPurple.opacity(0.3)))
                                        .foregroundColor(deepPurple)
                                }
                            }
                            
                            if let sum = summary {
                                Divider().padding(.vertical, 8)
                                Text("Why this score?").font(.subheadline).fontWeight(.bold).foregroundColor(deepPurple)
                                Text(sum).font(.caption).foregroundColor(deepPurple.opacity(0.8))
                            }
                        }
                        .padding()
                    }
                    
                    // Close Button at Bottom
                    Button(action: { withAnimation { showAnalysisModal = false } }) {
                        Text("Close")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(accentPurple).cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showAnalysisModal)
        }
    }
    
    // MARK: - Strategy Modal
    @ViewBuilder
    private var strategyModalOverlay: some View {
        if showStrategyModal, let strategy = strategicAdvice {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showStrategyModal = false } }
                
                VStack(spacing: 0) {
                    HStack {
                        Text("🧭 Cosmic Strategy").font(.headline).foregroundColor(deepPurple)
                        Spacer()
                        Button(action: { withAnimation { showStrategyModal = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundColor(accentPurple.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(accentPurple.opacity(0.1))
                    
                    ScrollView {
                        Text(strategy)
                            .font(.system(size: 16, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(deepPurple)
                            .lineSpacing(8)
                            .padding()
                    }
                    
                    Button(action: { withAnimation { showStrategyModal = false } }) {
                        Text("Close")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(accentPurple).cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showStrategyModal)
        }
    }
    
    // MARK: - Power Hours Modal
    @ViewBuilder
    private var powerHoursModalOverlay: some View {
        if showPowerHoursModal, let slots = luckyTimeSlots, !slots.isEmpty {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showPowerHoursModal = false } }
                
                VStack(spacing: 0) {
                    HStack {
                        Text("⏰ Power Hours").font(.headline).foregroundColor(deepPurple)
                        Spacer()
                        Button(action: { withAnimation { showPowerHoursModal = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundColor(accentGold.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(accentGold.opacity(0.15))
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(slots, id: \.self) { slot in
                                Text(slot)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(deepPurple)
                                    .padding(16)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentGold, lineWidth: 1.5))
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: { withAnimation { showPowerHoursModal = false } }) {
                        Text("Close")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(accentGold).cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showPowerHoursModal)
        }
    }
    
    // MARK: - Astro Insights Modal
    @ViewBuilder
    private var astroInsightsModalOverlay: some View {
        if showReport {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showReport = false } }
                
                VStack(spacing: 0) {
                    HStack {
                        Text("🌟 Daily Astro Insights").font(.headline).foregroundColor(deepPurple)
                        Spacer()
                        Button(action: { withAnimation { showReport = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundColor(accentPurple.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(accentPurple.opacity(0.1))
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoadingChart {
                                ProgressView("Consulting the stars...")
                                    .frame(maxWidth: .infinity, minHeight: 150)
                            } else if let chart = chartData {
                                // Ascendant
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("🌅 Your Rising Sign (Ascendant)")
                                        .font(.subheadline).fontWeight(.semibold).foregroundColor(accentPurple)
                                    Text(chart.ascendant)
                                        .font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                                    Text("This sign represents your outer personality and how you interact with the world today.")
                                        .font(.caption).foregroundColor(deepPurple.opacity(0.7))
                                }
                                .padding()
                                .background(accentPurple.opacity(0.1))
                                .cornerRadius(12)
                                
                                Text("🌟 Key Planetary Influences").font(.subheadline).fontWeight(.bold).foregroundColor(deepPurple)
                                
                                ForEach(Array(chart.planets.keys.sorted()), id: \.self) { key in
                                    if ["Sun", "Moon", "Mars", "Jupiter", "Venus"].contains(key),
                                       let planet = chart.planets[key] {
                                        HStack(alignment: .top, spacing: 10) {
                                            Text("•").foregroundColor(accentGold)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("\(key) in \(planet.sign)").fontWeight(.semibold).foregroundColor(deepPurple)
                                                Text("Bringing \(getPlanetKeyword(key)) energy to your life.")
                                                    .font(.caption).foregroundColor(deepPurple.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                
                                // Chart Strength
                                VStack {
                                    Text("Chart Strength: \(chart.strength_score)/100")
                                        .font(.headline).foregroundColor(deepPurple)
                                    Text("A higher score indicates stronger planetary support.")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(accentGold.opacity(0.2))
                                .cornerRadius(12)
                                
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.orange)
                                    Text("Insights Unavailable").font(.headline).foregroundColor(deepPurple)
                                    Text("Please ensure you entered a Birth Time and have an internet connection.")
                                        .multilineTextAlignment(.center).font(.caption).foregroundColor(deepPurple.opacity(0.7))
                                }
                                .frame(maxWidth: .infinity, minHeight: 150)
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: { withAnimation { showReport = false } }) {
                        Text("Close")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(accentPurple).cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showReport)
        }
    }
    
    // MARK: - Powerball Modal
    @ViewBuilder
    private var powerballModalOverlay: some View {
        if showPowerballModal {
            ZStack {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { withAnimation { showPowerballModal = false } }
                
                VStack(spacing: 0) {
                    HStack {
                        Text("🎱 Lucky Powerball Numbers").font(.headline).foregroundColor(deepPurple)
                        Spacer()
                        Button(action: { withAnimation { showPowerballModal = false } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2).foregroundColor(accentPurple.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(accentPurple.opacity(0.1))
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Section 1: Personal Powerball
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("🌟").font(.title3)
                                    Text("YOUR PERSONAL LUCKY NUMBERS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(1)
                                        .foregroundColor(accentGold)
                                }
                                
                                if let personal = personalPowerball {
                                    HStack(spacing: 8) {
                                        ForEach(personal.white_balls, id: \.self) { num in
                                            lottoBall(num, isRed: false)
                                        }
                                        
                                        Rectangle()
                                            .fill(accentGold.opacity(0.3))
                                            .frame(width: 2, height: 30)
                                            .padding(.horizontal, 4)
                                        
                                        lottoBall(personal.powerball, isRed: true)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(accentGold.opacity(0.05))
                                    .cornerRadius(12)
                                    
                                    Text("Based on your birth chart - these numbers stay with you.")
                                        .font(.caption)
                                        .foregroundColor(deepPurple.opacity(0.6))
                                        .italic()
                                        .frame(maxWidth: .infinity, alignment: .center)
                                } else {
                                    Text("Calculation pending...")
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                            
                            // Section 2: Daily Powerballs
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("📅").font(.title3)
                                    Text("TODAY'S TOP 10 COMBINATIONS")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .tracking(1)
                                        .foregroundColor(accentPurple)
                                }
                                
                                if let daily = dailyPowerballs, !daily.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(Array(daily.enumerated()), id: \.offset) { index, combo in
                                            VStack(alignment: .leading, spacing: 6) {
                                                Text("Combination #\(index + 1)")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(deepPurple.opacity(0.5))
                                                
                                                HStack(spacing: 6) {
                                                    ForEach(combo.white_balls, id: \.self) { num in
                                                        lottoBall(num, isRed: false, size: 30)
                                                    }
                                                    
                                                    Rectangle()
                                                        .fill(accentPurple.opacity(0.2))
                                                        .frame(width: 1, height: 20)
                                                        .padding(.horizontal, 2)
                                                    
                                                    lottoBall(combo.powerball, isRed: true, size: 30)
                                                }
                                            }
                                            .padding(10)
                                            .frame(maxWidth: .infinity)
                                            .background(accentPurple.opacity(0.03))
                                            .cornerRadius(10)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(accentPurple.opacity(0.1), lineWidth: 1))
                                        }
                                    }
                                } else {
                                    Text("No daily combinations available.")
                                        .font(.caption).foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                        }
                        .padding()
                    }
                    
                    Button(action: { withAnimation { showPowerballModal = false } }) {
                        Text("Close")
                            .font(.headline).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(accentPurple).cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(24)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showPowerballModal)
        }
    }
    
    // Lotto Ball Helper
    @ViewBuilder
    private func lottoBall(_ number: Int, isRed: Bool, size: CGFloat = 38) -> some View {
        Text("\(number)")
            .font(.system(size: size * 0.45, weight: .bold, design: .rounded))
            .foregroundColor(isRed ? .white : deepPurple)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isRed ? Color.red : Color.white)
                    .shadow(color: (isRed ? Color.red : Color.gray).opacity(0.2), radius: 2)
            )
            .overlay(
                Circle()
                    .stroke(isRed ? Color.red : accentPurple.opacity(0.3), lineWidth: size * 0.05)
            )
    }
    
    // Helper
    func getDayName(_ dateStr: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        // Try strict format
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: dateStr) {
            f.dateFormat = "EEE" // "Mon"
            return f.string(from: d)
        }
        
        // Try ISO text fallback
        let isoFn = ISO8601DateFormatter()
        // If it includes time
        isoFn.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        if let d = isoFn.date(from: dateStr) {
             f.dateFormat = "EEE"
             return f.string(from: d)
        }

        // Final Fallback: Slicing (Assume YYYY-MM-DD)
        // If slicing fails (empty), return "?"
        if dateStr.count >= 10 {
            // Can't reliably manually verify day of week without calendar
            // So return "Day" or placeholder
             return "?"
        }
        return "?"
    }
    
    func formatDayMonth(_ dateStr: String) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        if let d = f.date(from: dateStr) {
            f.dateFormat = "EEE, MMM d" // "Sun, Dec 15"
            return f.string(from: d)
        }
        
        // Try ISO/Lenient
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate]
        if let d = iso.date(from: dateStr) {
             f.dateFormat = "EEE, MMM d"
             return f.string(from: d)
        }
        
        return dateStr
    }
    
    func getPlanetKeyword(_ planet: String) -> String {
        let keywords = [
            "Sun": "vitality & ego", "Moon": "emotional & intuitive",
            "Mars": "drive & action", "Mercury": "communication",
            "Jupiter": "growth & luck", "Venus": "love & creative",
            "Saturn": "discipline", "Rahu": "obsessive", "Ketu": "spiritual"
        ]
        return keywords[planet] ?? "cosmic"
    }
}

struct ResultView_Previews: PreviewProvider {
    static var previews: some View {
        ResultView(
            percentage: 88,
            explanation: OmniLuckLogic.LuckExplanation(text: "Preview Text", traits: ["Bold", "Lucky"]),
            birthInfo: nil
        )
    }
}
