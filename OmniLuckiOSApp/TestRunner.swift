import Foundation

// Test Runner for OmniLuckLogic
struct TestRunner {
    static func runTests() {
        let testName = "John Doe"
        // Date: 1990-01-01
        var components = DateComponents()
        components.year = 1990
        components.month = 1
        components.day = 1
        let testDob = Calendar.current.date(from: components)!
        
        print("Running Logic Tests...")
        let percent = OmniLuckLogic.calculateLuckyPercentage(name: testName, dob: testDob)
        print("Test Case 1: Name: \(testName), DOB: 1990-01-01 -> Result: \(percent)%")
        
        if percent >= 0 && percent <= 100 {
            print("✅ Result is within valid range (0-100)")
        } else {
            print("❌ Result is OUT OF RANGE")
        }
        
        // Deterministic Check
        let percent2 = OmniLuckLogic.calculateLuckyPercentage(name: testName, dob: testDob)
        if percent == percent2 {
            print("✅ Logic is deterministic")
        } else {
            print("❌ Logic is NOT deterministic")
        }
        
        print("Tests Completed.")
    }
}
