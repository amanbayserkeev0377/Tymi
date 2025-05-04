import XCTest
@testable import Tymi

final class HabitTimerServiceTests: XCTestCase {
    
    var timerService: HabitTimerService!
    
    override func setUp() {
        super.setUp()
        // Reset UserDefaults for tests
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "habit.timer.data")
        userDefaults.removeObject(forKey: "habit.background.time")
        userDefaults.removeObject(forKey: "habit.active.timers")
        
        timerService = HabitTimerService.shared
    }
    
    override func tearDown() {
        // Clean up after each test
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "habit.timer.data")
        userDefaults.removeObject(forKey: "habit.background.time")
        userDefaults.removeObject(forKey: "habit.active.timers")
        super.tearDown()
    }
    
    // Test starting and stopping timer
    func testStartStopTimer() {
        let habitId = "test_habit_1"
        
        // Initial state
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 0)
        XCTAssertFalse(timerService.isTimerRunning(for: habitId))
        
        // Start timer
        timerService.startTimer(for: habitId)
        XCTAssertTrue(timerService.isTimerRunning(for: habitId))
        
        // Stop timer
        timerService.stopTimer(for: habitId)
        XCTAssertFalse(timerService.isTimerRunning(for: habitId))
    }
    
    // Test adding progress
    func testAddProgress() {
        let habitId = "test_habit_2"
        
        // Initial state
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 0)
        
        // Add progress
        timerService.addProgress(60, for: habitId)
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 60)
        
        // Add more progress
        timerService.addProgress(30, for: habitId)
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 90)
    }
    
    // Test resetting timer
    func testResetTimer() {
        let habitId = "test_habit_3"
        
        // Add some progress
        timerService.addProgress(120, for: habitId)
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 120)
        
        // Reset timer
        timerService.resetTimer(for: habitId)
        XCTAssertEqual(timerService.getCurrentProgress(for: habitId), 0)
    }
    
    // Test timer continues to update progress
    func testTimerUpdatesProgress() {
        let habitId = "test_habit_4"
        
        // Start timer
        timerService.startTimer(for: habitId)
        
        // Wait for 2 seconds
        let expectation = XCTestExpectation(description: "Wait for timer to update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            // Progress should be at least 2 seconds
            XCTAssertGreaterThanOrEqual(self.timerService.getCurrentProgress(for: habitId), 2)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // Test app background handling
    func testAppBackgroundHandling() {
        let habitId = "test_habit_5"
        
        // Start timer
        timerService.startTimer(for: habitId)
        
        // Wait briefly
        Thread.sleep(forTimeInterval: 0.5)
        
        // Simulate app going to background
        timerService.handleAppDidEnterBackground()
        
        // Simulate time in background (5 seconds)
        let backgroundTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(backgroundTime - 5, forKey: "habit.background.time")
        
        // Simulate app coming back to foreground
        timerService.handleAppWillEnterForeground()
        
        // Progress should include background time
        XCTAssertGreaterThanOrEqual(timerService.getCurrentProgress(for: habitId), 5)
    }
}
