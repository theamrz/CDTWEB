import Foundation

/// تبدیل‌گر تاریخ میلادی به شمسی (جلالی)
enum JalaliDateConverter {
    
    private static let gregorianDaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    private static let jalaliDaysInMonth = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29]
    
    /// آیا سال میلادی کبیسه است؟
    private static func isGregorianLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    /// تبدیل تاریخ میلادی به شمسی
    /// - Returns: tuple از (سال, ماه, روز) شمسی
    static func toJalali(year gy: Int, month gm: Int, day gd: Int) -> (year: Int, month: Int, day: Int) {
        let gy2 = gy - 1600
        let gm2 = gm - 1
        let gd2 = gd - 1
        
        var gDayNo = 365 * gy2 + (gy2 + 3) / 4 - (gy2 + 99) / 100 + (gy2 + 399) / 400
        
        for i in 0..<gm2 {
            gDayNo += gregorianDaysInMonth[i]
        }
        if gm2 > 1 && isGregorianLeap(gy) {
            gDayNo += 1
        }
        gDayNo += gd2
        
        var jDayNo = gDayNo - 79
        let jNp = jDayNo / 12053
        jDayNo %= 12053
        
        var jy = 979 + 33 * jNp + 4 * (jDayNo / 1461)
        jDayNo %= 1461
        
        if jDayNo >= 366 {
            jy += (jDayNo - 1) / 365
            jDayNo = (jDayNo - 1) % 365
        }
        
        var jm = 0
        var jd = 0
        
        for i in 0..<11 {
            if jDayNo < jalaliDaysInMonth[i] {
                jm = i + 1
                jd = jDayNo + 1
                break
            }
            jDayNo -= jalaliDaysInMonth[i]
        }
        
        if jm == 0 {
            jm = 12
            jd = jDayNo + 1
        }
        
        return (jy, jm, jd)
    }
    
    /// تبدیل Date به تاریخ شمسی
    static func toJalali(_ date: Date) -> (year: Int, month: Int, day: Int) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return toJalali(
            year: components.year ?? 2024,
            month: components.month ?? 1,
            day: components.day ?? 1
        )
    }
    
    /// فرمت برای نام پوشه/فایل: YYYY-MM-DD_HH-MM
    static func formatStamp(_ date: Date) -> String {
        let jalali = toJalali(date)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        
        return String(format: "%04d-%02d-%02d_%02d-%02d",
                     jalali.year, jalali.month, jalali.day, hour, minute)
    }
    
    /// فرمت خوانا برای نمایش: YYYY-MM-DD HH:MM:SS
    static func formatReadable(_ date: Date) -> String {
        let jalali = toJalali(date)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        return String(format: "%04d-%02d-%02d %02d:%02d:%02d",
                     jalali.year, jalali.month, jalali.day, hour, minute, second)
    }
    
    /// فرمت میلادی برای نمایش
    static func formatGregorian(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    /// فرمت ISO برای timestamp
    static func formatISO(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}
