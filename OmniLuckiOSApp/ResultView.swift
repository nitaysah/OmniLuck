import SwiftUI

struct ResultView: View {
    let percentage: Int
    let explanation: OmniLuckLogic.LuckExplanation
    // Birth Info for fetching chart
    var birthInfo: (dob: Date, time: Date, place: String)? = nil
    
    @Environment(\.dismiss) var dismiss
    
    @State private var displayedPercentage = 0
    @State private var isAnimating = false
    @State private var showCard = false
    @State private var showReport = false
    
    // Chart Data State
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
            
            VStack(spacing: 30) {
                Spacer()
                
                // Result Animation
                VStack(spacing: 20) {
                    Text("Your Daily Luck")
                        .font(.title2).fontWeight(.medium).foregroundColor(deepPurple)
                        .opacity(isAnimating ? 1 : 0).offset(y: isAnimating ? 0 : 20)
                        .animation(.easeOut(duration: 0.5), value: isAnimating)
                    
                    // Zodiac from Birth Info (Moved down)
                    
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
                }
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
                }
                
                // Expl Card
                if showCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "sparkle.magnifyingglass").foregroundColor(deepPurple)
                            Text("Daily Luck Analysis").font(.headline).foregroundColor(deepPurple)
                        }
                        Text(explanation.text).font(.subheadline).foregroundColor(deepPurple.opacity(0.8)).lineSpacing(4)
                        
                        HStack(spacing: 10) {
                            ForEach(explanation.traits, id: \.self) { trait in
                                Text(trait).font(.caption).fontWeight(.semibold).padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(accentPurple.opacity(0.5)).overlay(Capsule().stroke(accentGold.opacity(0.5), lineWidth: 1)))
                                    .foregroundColor(deepPurple)
                            }
                        }
                    }
                    .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.7)).overlay(RoundedRectangle(cornerRadius: 20).stroke(accentPurple.opacity(0.3), lineWidth: 1)))
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    // Zodiac Display
                    if let info = birthInfo {
                        let zodiac = OmniLuckLogic.getZodiacSign(date: info.dob)
                        VStack(spacing: 4) {
                            Text("Your Zodiac Sign")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .textCase(.uppercase)
                                .foregroundColor(deepPurple.opacity(0.6))
                            HStack(spacing: 8) {
                                Text(zodiac.icon).font(.largeTitle)
                                Text(zodiac.name).font(.title3).fontWeight(.bold).foregroundColor(deepPurple)
                            }
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity) // Center align
                    }
                    
                    // Daily Report Button
                    Button(action: { showReport = true }) {
                        HStack(spacing: 8) {
                            Text("📜")
                            Text("Read my Daily Luck Report")
                        }
                        .font(.subheadline).fontWeight(.semibold).foregroundColor(deepPurple)
                        .padding(.vertical, 12).padding(.horizontal, 20)
                        .background(Color.white.opacity(0.5)).cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(accentPurple.opacity(0.5), lineWidth: 1))
                    }
                    .padding(.top, 10)
                    .sheet(isPresented: $showReport) {
                        // DAILY COSMIC REPORT SHEET
                        NavigationView {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 20) {
                                    if isLoadingChart {
                                        ProgressView("Consulting the stars...")
                                            .frame(maxWidth: .infinity, minHeight: 200)
                                    } else if let chart = chartData {
                                        
                                        // Ascendant
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Your Rising Sign (Ascendant): \(chart.ascendant)")
                                                .font(.headline).foregroundColor(accentPurple)
                                            Text("This sign represents your outer personality and how you interact with the world today.")
                                                .font(.body).foregroundColor(deepPurple.opacity(0.8))
                                        }
                                        .padding().background(Color.white.opacity(0.5)).cornerRadius(12)
                                        
                                        Divider()
                                        
                                        Text("Key Planetary Influences").font(.headline).padding(.top, 10).foregroundColor(deepPurple)
                                        
                                        // Planets List
                                        VStack(alignment: .leading, spacing: 12) {
                                            ForEach(Array(chart.planets.keys.sorted()), id: \.self) { key in
                                                if ["Sun", "Moon", "Mars", "Jupiter", "Venus"].contains(key),
                                                   let planet = chart.planets[key] {
                                                    HStack(alignment: .top) {
                                                        Text("•").foregroundColor(accentGold)
                                                        VStack(alignment: .leading) {
                                                            Text("\(key) in \(planet.sign)").fontWeight(.bold)
                                                            Text("Bringing \(getPlanetKeyword(key)) energy to your life.")
                                                                .font(.subheadline).foregroundColor(deepPurple.opacity(0.7))
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Score
                                        VStack {
                                            Text("Chart Strength: \(chart.strength_score)/100")
                                                .font(.headline).foregroundColor(deepPurple)
                                            Text("A higher score indicates stronger planetary support.").font(.caption).foregroundColor(.gray)
                                        }
                                        .padding().frame(maxWidth: .infinity).background(accentGold.opacity(0.3)).cornerRadius(10).padding(.top, 20)
                                        
                                    } else {
                                        VStack(spacing: 20) {
                                            Image(systemName: "exclamationmark.triangle").font(.largeTitle).foregroundColor(.orange)
                                            Text("Report Unavailable")
                                            Text("Please ensure you entered a Birth Time and have an internet connection.")
                                                .multilineTextAlignment(.center).font(.caption)
                                        }
                                        .frame(maxWidth: .infinity, minHeight: 200)
                                    }
                                }
                                .padding()
                            }
                            .navigationTitle("Daily Cosmic Report")
                            .navigationBarTitleDisplayMode(.inline)
                            .task {
                                // Fetch chart on load if needed
                                if chartData == nil, let info = birthInfo {
                                    isLoadingChart = true
                                    do {
                                        chartData = try await NetworkService.shared.fetchNatalChart(
                                            dob: info.dob,
                                            birthTime: info.time,
                                            birthPlace: info.place
                                        )
                                    } catch {
                                        print("Chart Error: \(error)")
                                    }
                                    isLoadingChart = false
                                }
                            }
                        }
                        .presentationDetents([.medium, .large])
                    }
                }
                Spacer()
                
                // Home Button
                Button(action: { dismiss() }) {
                    HStack(spacing: 10) { Image(systemName: "house.fill"); Text("Home") }
                        .font(.headline).foregroundColor(deepPurple).padding(.vertical, 16).frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [accentGold, accentGold.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(16).shadow(color: accentGold.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal).padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    // Helper
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
