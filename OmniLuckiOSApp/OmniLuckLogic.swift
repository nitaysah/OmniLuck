import Foundation

struct OmniLuckLogic {
    /// Calculates a "lucky percentage" (0-100) based on name and date of birth.
    static func calculateLuckyPercentage(name: String, dob: Date) -> Int {
        let calendar = Calendar.current
        
        // 1. Calculate Life Path Number
        let components = calendar.dateComponents([.year, .month, .day], from: dob)
        let day = components.day ?? 0
        let month = components.month ?? 0
        let year = components.year ?? 0
        
        let lifePathNumber = reduceToSingleDigit(day) + reduceToSingleDigit(month) + reduceToSingleDigit(year)
        let finalLifePath = reduceToSingleDigit(lifePathNumber)
        
        // 2. Daily Seed
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        let dailyString = "\(today.year!)\(today.month!)\(today.day!)"
        
        // 3. Name Hash
        let nameHash = name.lowercased().reduce(0) { $0 + Int($1.asciiValue ?? 0) }
        
        // 4. Combine
        let combinedString = "\(finalLifePath)-\(nameHash)-\(dailyString)"
        let hash = combinedString.reduce(5381) {
            ($0 << 5) &+ $0 &+ Int($1.asciiValue ?? 0)
        }
        
        // 5. Normalize to 0-100
        let percentage = abs(hash) % 101
        
        return percentage
    }
    
    private static func reduceToSingleDigit(_ number: Int) -> Int {
        var n = number
        while n > 9 {
            var sum = 0
            while n > 0 {
                sum += n % 10
                n /= 10
            }
            n = sum
        }
        return n
    }
    
    /// Returns the Zodiac sign and corresponding emoji icon for a given date
    static func getZodiacSign(date: Date) -> (name: String, icon: String) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .month], from: date)
        let day = components.day ?? 0
        let month = components.month ?? 0
        
        switch month {
        case 1: return (day >= 20) ? ("Aquarius", "♒") : ("Capricorn", "♑")
        case 2: return (day >= 19) ? ("Pisces", "♓") : ("Aquarius", "♒")
        case 3: return (day >= 21) ? ("Aries", "♈") : ("Pisces", "♓")
        case 4: return (day >= 20) ? ("Taurus", "♉") : ("Aries", "♈")
        case 5: return (day >= 21) ? ("Gemini", "♊") : ("Taurus", "♉")
        case 6: return (day >= 22) ? ("Cancer", "♋") : ("Gemini", "♊")
        case 7: return (day >= 23) ? ("Leo", "♌") : ("Cancer", "♋")
        case 8: return (day >= 23) ? ("Virgo", "♍") : ("Leo", "♌")
        case 9: return (day >= 23) ? ("Libra", "♎") : ("Virgo", "♍")
        case 10: return (day >= 24) ? ("Scorpio", "♏") : ("Libra", "♎")
        case 11: return (day >= 23) ? ("Sagittarius", "♐") : ("Scorpio", "♏")
        case 12: return (day >= 22) ? ("Capricorn", "♑") : ("Sagittarius", "♐")
        default: return ("Unknown", "❓")
        }
    }
    
    struct LuckExplanation {
        let text: String
        let traits: [String]
    }
    
    static func generateLuckExplanation(percentage: Int, name: String, dob: Date) -> LuckExplanation {
        let (sign, _) = getZodiacSign(date: dob)
        
        // Traits selected based on percentage directly (changes when percentage changes)
        let allTraits = [
            "Resilient", "Intuitive", "Charismatic", "Analytical", "Creative",
            "Bold", "Empathetic", "Strategic", "Patient", "Adaptive",
            "Visionary", "Determined", "Compassionate", "Resourceful", "Optimistic",
            "Courageous", "Wise", "Confident", "Ambitious", "Graceful"
        ]
        
        // Use percentage to select traits - different percentage = different traits
        let trait1 = allTraits[percentage % allTraits.count]
        let trait2 = allTraits[(percentage * 7) % allTraits.count]
        let trait3 = allTraits[(percentage * 13) % allTraits.count]
        let selectedTraits = [trait1, trait2, trait3].unique()
        
        // === EXCEPTIONAL LUCK (85-100) ===
        let exceptionalStatements = [
            "The stars have aligned perfectly for you today! Fortune favors the bold, and you're radiating unstoppable energy.",
            "An extraordinary wave of cosmic luck surrounds you. The universe is conspiring in your favor!",
            "Your celestial chart reveals a rare golden alignment. Today, you are a magnet for good things.",
            "The star of riches is shining brightly upon you. Expect unexpected blessings and thrilling opportunities.",
            "You're on a legendary lucky streak! The cosmos has opened its treasure chest just for you.",
            "I am capable of achieving greatness—and today proves it! Success and prosperity flow toward you.",
            "Everything is going according to plan. You're in the right place at the right time.",
            "Your hard work is about to pay off magnificently. Trust your instincts—they're supercharged today."
        ]
        
        let exceptionalInsights = [
            "Take bold action; success will follow you.",
            "An unexpected opportunity may change everything.",
            "Love and abundance are flowing your way.",
            "You attract success and prosperity effortlessly.",
            "Every day you are getting closer to reaching your goals.",
            "The universe conspires in your favor to achieve your dreams.",
            "You are energized by your goals and dreams.",
            "Trust that miracles are happening right now."
        ]
        
        // === GREAT LUCK (70-84) ===
        let greatStatements = [
            "Your \(sign) energy is harmonizing beautifully with today's celestial movements. Great things await!",
            "The cosmic winds are blowing strongly in your favor. You have the power to create a life you love.",
            "Fortune is smiling upon you today. Your heart is in a place to draw true happiness.",
            "A thrilling time is in your near future. The cards reveal what the heart conceals.",
            "Your aura is glowing with positive vibrations. You're worthy of all the good coming your way.",
            "I am confident in my abilities and decisions—and so should you be today!",
            "You embrace challenges as opportunities to grow. That mindset is paying off.",
            "Positive energy attracts positive outcomes. Keep shining!"
        ]
        
        let greatInsights = [
            "Now is the time to try something new—you will benefit.",
            "Someone special is thinking of you right now.",
            "A decision you've been pondering will become clear.",
            "Your creativity is at its peak—express yourself!",
            "I am open to new possibilities and opportunities.",
            "I am constantly growing and improving.",
            "I believe in myself and my vision.",
            "Great things are unfolding for me."
        ]
        
        // === MODERATE LUCK (50-69) ===
        let moderateStatements = [
            "As a \(sign), you're navigating steady cosmic currents today. Balance is your superpower.",
            "The universe is working behind the scenes for you. Patience will reveal hidden blessings.",
            "Your path is illuminated with gentle moonlight. Trust the journey you're on.",
            "Moderate fortune surrounds you—stay grounded and watch for subtle signs.",
            "Today brings stability and quiet strength. You're exactly where you need to be.",
            "Life is 10% what happens to you and 90% of how you react to it. React wisely.",
            "Luck is what happens when preparation meets opportunity. Keep preparing.",
            "Small steps today lead to big wins tomorrow."
        ]
        
        let moderateInsights = [
            "Focus on gratitude—it multiplies your blessings.",
            "A friend may offer valuable advice today.",
            "Stay open to unexpected conversations.",
            "Your resilience is being recognized by the universe.",
            "I am in the right place at the right time.",
            "I trust the timing of my life.",
            "Every experience is valuable for my growth.",
            "I am exactly where I need to be."
        ]
        
        // === LOW LUCK (30-49) ===
        let lowStatements = [
            "The cosmic energy is asking you to slow down and reflect. Tomorrow's fortunes are the dreams of today.",
            "As a \(sign), you're being called to conserve your energy. This is a time for inner growth.",
            "The stars suggest a quiet day ahead. Use this time to recharge your spirit.",
            "Fortune is taking a brief pause—but remember, you are capable of figuring this out.",
            "A gentle reminder from the cosmos: every day can't be extraordinary, and that's okay.",
            "You have to remember that the hard days are what make you stronger.",
            "A bad day doesn't cancel out a good life. Keep going.",
            "This too shall pass. Your comeback story is being written."
        ]
        
        let lowInsights = [
            "Rest and self-care will amplify tomorrow's luck.",
            "Avoid major decisions—clarity comes with time.",
            "Something you lost may turn up soon.",
            "Embrace the calm; it precedes the storm of success.",
            "Your needs are important and valid. Honor them.",
            "I am resilient and can overcome any obstacle.",
            "Tomorrow holds brighter possibilities.",
            "Every setback is a setup for a comeback."
        ]
        
        // === VERY LOW LUCK (0-29) ===
        let veryLowStatements = [
            "The celestial bodies are in a protective formation. Lay low and trust that this too shall pass.",
            "Today's chart urges caution, but remember: you are resilient and can overcome any challenge.",
            "The universe is asking you to pause and redirect. Sometimes delay is divine protection.",
            "Low cosmic energy today, but your inner strength remains unshakable. You've got this!",
            "The stars advise patience. Fortune favors those who wait wisely.",
            "Tough times never last, but tough people do. You are tougher than you know.",
            "Our greatest glory is not in never falling, but in rising every time we fall.",
            "Even unlucky days end, but your spirit decides what stays behind."
        ]
        
        let veryLowInsights = [
            "Postpone risks; focus on what you can control.",
            "Unexpected help may arrive when you least expect it.",
            "Use this time for planning and preparation.",
            "Stars can't shine without darkness. Your light is coming.",
            "Hardships often prepare ordinary people for an extraordinary destiny.",
            "The best view comes after the hardest climb.",
            "Resilience is stitched together from the fabric of unlucky moments.",
            "A run of bad luck is only a detour, not a destination."
        ]
        
        // Select statement and insight based on percentage (directly!)
        let fortuneStatement: String
        let cosmicInsight: String
        
        if percentage >= 85 {
            fortuneStatement = exceptionalStatements[percentage % exceptionalStatements.count]
            cosmicInsight = exceptionalInsights[percentage % exceptionalInsights.count]
        } else if percentage >= 70 {
            fortuneStatement = greatStatements[percentage % greatStatements.count]
            cosmicInsight = greatInsights[percentage % greatInsights.count]
        } else if percentage >= 50 {
            fortuneStatement = moderateStatements[percentage % moderateStatements.count]
            cosmicInsight = moderateInsights[percentage % moderateInsights.count]
        } else if percentage >= 30 {
            fortuneStatement = lowStatements[percentage % lowStatements.count]
            cosmicInsight = lowInsights[percentage % lowInsights.count]
        } else {
            fortuneStatement = veryLowStatements[percentage % veryLowStatements.count]
            cosmicInsight = veryLowInsights[percentage % veryLowInsights.count]
        }
        
        let fullExplanation = """
        \(fortuneStatement)
        
        ✨ \(cosmicInsight)
        
        Your \(sign) cosmic profile suggests unique energy shifts are active for you today.
        """
        
        return LuckExplanation(text: fullExplanation, traits: Array(selectedTraits.prefix(3)))
    }
}

extension Array where Element: Hashable {
    func unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
