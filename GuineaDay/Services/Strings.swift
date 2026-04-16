// Strings.swift
// GuineaDay
//
// All user-visible UI strings in one place.
// Access via: @EnvironmentObject var lang: LanguageManager  →  lang.memoriesTitle
// The isZh shorthand picks the right language.

import Foundation

extension LanguageManager {

    // MARK: - Tab labels
    var tabHome:    String { isZh ? "主页"   : "Home" }
    var tabDuties:  String { isZh ? "任务"   : "Duties" }
    var tabGallery: String { isZh ? "相册"   : "Gallery" }
    var tabPiggies: String { isZh ? "豚豚"   : "Piggies" }
    var tabPlay:    String { isZh ? "游戏"   : "Play" }

    // MARK: - Common actions
    var save:   String { isZh ? "保存" : "Save" }
    var cancel: String { isZh ? "取消" : "Cancel" }
    var delete: String { isZh ? "删除" : "Delete" }
    var done:   String { isZh ? "完成" : "Done" }
    var remove: String { isZh ? "移除" : "Remove" }
    var change: String { isZh ? "更改" : "Change" }
    var retry:  String { isZh ? "重试" : "Retry" }
    var leave:  String { isZh ? "退出" : "Leave" }
    var orDivider: String { isZh ? "或"   : "or" }

    // MARK: - Dashboard
    var welcomeTitle:     String { isZh ? "GuineaDay ✦"           : "GuineaDay ✦" }
    var welcomeBody:      String { isZh ? "欢迎回来！\n你的豚豚们想你了~ 🥕" : "Welcome back!\nYour piggies miss you~ 🥕" }
    var statPiggies:      String { isZh ? "豚豚" : "Piggies" }
    var statTodo:         String { isZh ? "待办" : "To-Do" }
    var statMemories:     String { isZh ? "回忆" : "Memories" }
    var sectionTips:      String { isZh ? "豚豚小贴士"   : "Piggy Tips" }
    var tip1:             String { isZh ? "豚豚每天需要新鲜蔬菜！"          : "Guinea pigs need fresh veggies daily!" }
    var tip2:             String { isZh ? "每天换新鲜水 — 不容忽视。"       : "Fresh water every day — no exceptions." }
    var tip3:             String { isZh ? "每天至少1小时放风时间让它们更开心。" : "At least 1 hour of floor time keeps them happy." }
    var tip4:             String { isZh ? "豚豚是群居动物 — 它们喜欢同伴！"  : "Guinea pigs are social — they love company!" }
    var householdCode:    String { isZh ? "家庭邀请码" : "Household Code" }
    var chooseMascot:     String { isZh ? "选择你的吉祥物" : "Choose Your Mascot" }
    var yourOwn:          String { isZh ? "自定义" : "Your Own" }

    // MARK: - Task List
    var dutiestitle:            String { isZh ? "任务"       : "Duties" }
    func todoBadge(_ n: Int) -> String { isZh ? "待办 (\(n))" : "To-Do (\(n))" }
    func doneBadge(_ n: Int) -> String { isZh ? "已完成 (\(n))" : "Done (\(n))" }
    var allDoneEmpty:           String { isZh ? "全部完成了 — 太棒啦！🎉" : "All done — great job! 🎉" }

    // MARK: - Add Task
    var newTask:          String { isZh ? "新任务"   : "New Task" }
    var sectionTemplates: String { isZh ? "🐾 快速模板" : "🐾 Quick Templates" }
    var sectionDetails:   String { isZh ? "📋 任务详情" : "📋 Details" }
    var labelTitle:       String { isZh ? "标题"     : "TITLE" }
    var labelDueDate:     String { isZh ? "截止日期"  : "DUE DATE" }
    var labelCategory:    String { isZh ? "分类"     : "CATEGORY" }
    var labelPriority:    String { isZh ? "优先级"   : "PRIORITY" }
    var sectionRepeat:    String { isZh ? "🔁 重复"  : "🔁 Repeat" }
    var sectionReminder:  String { isZh ? "🔔 提醒"  : "🔔 Reminder" }
    var taskPlaceholder:  String { isZh ? "需要做什么？" : "What needs to be done?" }
    var remindMe:         String { isZh ? "提醒我"   : "Remind me" }
    var remindAt:         String { isZh ? "提醒时间"  : "Remind at" }
    var notifDeniedMsg:   String { isZh ? "通知已关闭。请在\"设置 → GuineaDay\"中开启。" : "Notifications are disabled. Enable them in Settings → GuineaDay." }

    // Recurrence labels
    var recurrenceNone:    String { isZh ? "不重复" : "None" }
    var recurrenceDaily:   String { isZh ? "每天"   : "Daily" }
    var recurrenceWeekly:  String { isZh ? "每周"   : "Weekly" }
    var recurrenceMonthly: String { isZh ? "每月"   : "Monthly" }

    // Recurrence lookup (maps stored DB key → localized display string)
    func localizedRecurrence(_ stored: String) -> String {
        switch stored.lowercased() {
        case "daily":   return recurrenceDaily
        case "weekly":  return recurrenceWeekly
        case "monthly": return recurrenceMonthly
        default:        return recurrenceNone
        }
    }

    // Category labels
    var catFeeding:  String { isZh ? "🍽 喂食" : "🍽 Feeding" }
    var catCleaning: String { isZh ? "🧹 清洁" : "🧹 Cleaning" }
    var catHealth:   String { isZh ? "🩺 健康" : "🩺 Health" }
    var catPlay:     String { isZh ? "🐾 玩耍" : "🐾 Play" }
    var catOther:    String { isZh ? "📋 其他" : "📋 Other" }

    // Category lookup (maps stored DB key → localized display string with emoji)
    func localizedCategory(_ stored: String) -> String {
        switch stored.lowercased() {
        case "feeding":  return catFeeding
        case "cleaning": return catCleaning
        case "health":   return catHealth
        case "play":     return catPlay
        case "other":    return catOther
        default:         return stored.capitalized
        }
    }

    // Priority labels
    var priorityLow:    String { isZh ? "低" : "Low" }
    var priorityMedium: String { isZh ? "中" : "Medium" }
    var priorityHigh:   String { isZh ? "高" : "High" }

    // Priority lookup (maps stored DB key → localized display string)
    func localizedPriority(_ stored: String) -> String {
        switch stored.lowercased() {
        case "high":   return priorityHigh
        case "medium": return priorityMedium
        default:       return priorityLow
        }
    }

    // Template titles
    var tplChangeWater:  String { isZh ? "换水" : "Change water" }
    var tplFreshVeggies: String { isZh ? "新鲜蔬菜" : "Fresh veggies" }
    var tplRefillHay:    String { isZh ? "补充干草" : "Refill hay" }
    var tplFloorTime:    String { isZh ? "放风时间" : "Floor time" }
    var tplWeighPiggies: String { isZh ? "称体重" : "Weigh piggies" }
    var tplCleanCage:    String { isZh ? "清洁笼子" : "Clean cage" }
    var tplNailTrim:     String { isZh ? "修剪指甲" : "Nail trim" }
    var tplHealthCheck:  String { isZh ? "健康检查" : "Health check" }

    // MARK: - Gallery
    var memoriesTitle: String { isZh ? "回忆相册 🌸" : "Memories 🌸" }
    var noPhotosYet:   String { isZh ? "还没有照片哦！"    : "No memories yet!" }
    var addFirstPhoto: String { isZh ? "点击 + 上传第一张照片" : "Tap + to add your first photo" }
    var deletePhoto:   String { isZh ? "删除照片" : "Delete Photo" }
    var photoUploadFailed: String { isZh ? "照片上传失败" : "Photo Upload Failed" }
    var photoUploadFailedMsg: String { isZh ? "照片无法上传，请检查网络连接后重试。" : "Could not upload the photo. Please check your internet connection and try again." }
    var photoNotAvailable:    String { isZh ? "照片离线不可用" : "Photo Not Available Offline" }
    var photoNotAvailableMsg: String { isZh ? "无法加载该照片。如果您的iPhone使用了\"iCloud照片库 - 优化存储\"，照片可能仅存在于iCloud中。请联网后在照片App中下载后再试。" : "One or more photos could not be loaded. If your iPhone uses iCloud Photo Library with 'Optimize Storage', the original photo may only exist in iCloud. Connect to the internet to download it first, then try again." }

    // MARK: - Profile List
    var myPiggiesTitle:   String { isZh ? "我的豚豚 🐾" : "My Piggies 🐾" }
    func piggyCount(_ n: Int) -> String {
        if isZh { return "\(n) 只豚豚" }
        return "\(n) fuzzy friend\(n == 1 ? "" : "s")"
    }
    var noPiggiesYet:     String { isZh ? "还没有豚豚！"       : "No piggies yet!" }
    var addFirstPiggy:    String { isZh ? "点击 + 添加第一只豚豚" : "Tap + to add your first guinea pig" }
    var longPressHint:    String { isZh ? "长按卡片可删除"     : "Long press a card to delete" }
    var deletePiggyTitle: String { isZh ? "删除豚豚？"        : "Delete Piggy?" }
    var deletePiggyMsg:   String { isZh ? "此操作将永久删除该豚豚及其所有体重记录。" : "This will permanently delete the piggy and all weight records." }

    // MARK: - Profile Edit
    var addPiggy:      String { isZh ? "添加豚豚" : "Add Piggy" }
    var editPiggy:     String { isZh ? "编辑豚豚" : "Edit Piggy" }
    var labelName:     String { isZh ? "名字"   : "NAME" }
    var labelBirthday: String { isZh ? "生日"   : "BIRTHDAY" }
    var labelBreed:    String { isZh ? "品种"   : "BREED" }
    var labelGender:   String { isZh ? "性别"   : "GENDER" }
    var labelPhoto:    String { isZh ? "头像"   : "PHOTO" }
    var namePlaceholder: String { isZh ? "豚豚的名字…" : "Name your piggy…" }
    var photoUploadFailedProfile: String { isZh ? "照片上传失败" : "Photo Upload Failed" }
    var photoNotAvailableProfile: String { isZh ? "照片离线不可用" : "Photo Not Available Offline" }
    var photoNotAvailableProfileMsg: String { isZh ? "该照片无法加载。如果您的iPhone使用了\"iCloud照片库 - 优化存储\"，请联网后在照片App中下载该照片后再试。" : "This photo could not be loaded. If your iPhone uses iCloud Photo Library with 'Optimize Storage', the photo may only exist in iCloud. Connect to the internet to download it first, then try again." }

    // Gender display labels (stored value stays English in DB)
    var genderBoar: String { isZh ? "男生" : "Boar" }
    var genderSow:  String { isZh ? "女生" : "Sow" }
    func localizedGender(_ stored: String) -> String {
        switch stored {
        case "Boar": return genderBoar
        case "Sow":  return genderSow
        default:     return stored
        }
    }

    // MARK: - Weight Log
    var weightTracker:     String { isZh ? "体重记录"         : "Weight Tracker" }
    var noWeightRecords:   String { isZh ? "暂无记录 — 来添加第一次称重吧！" : "No records yet — add your first weigh-in!" }
    var weightHistory:     String { isZh ? "体重历史" : "Weight History" }
    var noChange:          String { isZh ? "无变化" : "No change" }

    // MARK: - Settings
    var settingsTitle:     String { isZh ? "设置" : "Settings" }
    var sectionRegion:     String { isZh ? "📍 地区" : "📍 Region" }
    var sectionLanguage:   String { isZh ? "🌐 语言" : "🌐 Language" }
    var regionNameLocal:   String { isZh ? "🇨🇳 中国大陆" : "🇨🇳 China Mainland" }
    var regionNameCloud:   String { isZh ? "🌏 国际版"  : "🌏 International" }
    var regionSubLocal:    String { isZh ? "本地存储 · Local only" : "Local only · 本地存储" }
    var regionSubCloud:    String { isZh ? "云端同步已启用" : "Cloud sync enabled" }
    var loading:           String { isZh ? "加载中…" : "Loading…" }
    var sectionHome:       String { isZh ? "🏡 我家" : "🏡 Our Home" }
    var labelHouseholdName: String { isZh ? "家庭名称" : "HOUSEHOLD NAME" }
    var labelInviteCode:   String { isZh ? "邀请码"   : "INVITE CODE" }
    var householdNamePlaceholder: String { isZh ? "给你们的家起个名字…" : "Give your home a name…" }
    var sectionMembers:    String { isZh ? "👥 成员"  : "👥 Members" }
    var labelMyNickname:   String { isZh ? "我的昵称"  : "MY NICKNAME" }
    var labelInHousehold:  String { isZh ? "家庭成员"  : "IN THIS HOUSEHOLD" }
    var nicknamePlaceholder: String { isZh ? "设置你的昵称…" : "Set your nickname…" }
    var youLabel:          String { isZh ? "我"      : "You" }
    var sectionAccount:    String { isZh ? "账户"     : "Account" }
    var leaveHousehold:    String { isZh ? "退出家庭"  : "Leave Household" }
    var sectionAbout:      String { isZh ? "ℹ️ 关于"  : "ℹ️ About" }
    var appVersion:        String { isZh ? "应用版本"  : "App Version" }

    // Alert: Leave household
    var leaveAlertTitle:   String { isZh ? "退出家庭？" : "Leave Household?" }
    var leaveAlertMsg:     String { isZh ? "本地数据将被清除。您可以加入或创建新家庭。" : "Your local data will be cleared. You can join or create a new household." }

    // Alert: Remove member
    var removeMemberMsg:   String { isZh ? "该成员将被移出家庭，此操作无法撤销。" : "They will be removed from the household. This cannot be undone." }

    // Alert: Change region
    var changeRegionTitle: String { isZh ? "更改地区？" : "Change Region?" }
    var switchToIntl:      String { isZh ? "切换到国际版" : "Switch to International" }
    var switchToChina:     String { isZh ? "切换到中国大陆" : "Switch to China Mainland" }
    var changeRegionToCloudMsg: String { isZh ? "切换到国际版将启用云端同步和家庭共享功能。您需要登录并加入或创建家庭。" : "Switching to International will enable cloud sync and household features. You'll need to sign in and join or create a household." }
    var changeRegionToLocalMsg: String { isZh ? "切换到中国大陆将暂停云端同步，应用将仅使用本地存储。在本地模式下添加的数据不会自动同步回云端。" : "Switching to China Mainland will pause cloud sync. The app will run on local storage only. Data added while in local mode won't sync back automatically." }

    // MARK: - Household Setup
    var setupTitle:          String { isZh ? "创建你的家"          : "Set Up Your Home" }
    var setupSubtitle:       String { isZh ? "创建家庭或加入伴侣的家 🏡" : "Create a home or join your partner's 🏡" }
    var sectionStartFresh:   String { isZh ? "全新开始"            : "Start Fresh" }
    var startFreshDesc:      String { isZh ? "创建一个新的共享家庭。\n您将获得一个邀请码分享给伴侣。" : "Create a new shared home.\nYou'll get an invite code to share with your partner." }
    var shareCodePrompt:     String { isZh ? "将此邀请码分享给伴侣 🏡" : "Share this code with your partner 🏡" }
    var copyCode:            String { isZh ? "复制邀请码" : "Copy Code" }
    var createNewHome:       String { isZh ? "创建新家庭" : "Create a New Home" }
    var sectionJoinHome:     String { isZh ? "加入家庭"           : "Join a Home" }
    var joinHomeDesc:        String { isZh ? "已有伴侣的邀请码？\n在下方输入即可加入。" : "Got an invite code from your partner?\nEnter it below to join their home." }
    var joinWithCode:        String { isZh ? "用邀请码加入" : "Join with Code" }

    // MARK: - Network Error (intentionally stays bilingual — user hasn't picked language yet)
    var networkErrorTitle:      String { isZh ? "无法连接"  : "Unable to Connect" }
    var networkErrorBody:       String { isZh ? "GuineaDay 需要访问国际网络服务（Firebase）。如果您在中国大陆，请使用 VPN 后重试。" : "GuineaDay requires access to international network services (Firebase). If you're in mainland China, please use a VPN and try again." }
    var skipNetwork:            String { isZh ? "跳过网络（使用本地模式）" : "Skip network (Use Local Mode)" }

    // MARK: - Invite Code Screen (RootView)
    var inviteCodeTitle:       String { isZh ? "你的邀请码"             : "Your Invite Code" }
    var inviteCodeSubtitle:    String { isZh ? "将此邀请码分享给伴侣，即可加入你的家庭" : "Share this with your partner so they can join your home" }
    var continueToApp:         String { isZh ? "进入应用 →" : "Continue to App →" }
}
