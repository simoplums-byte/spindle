import ServiceManagement

/// 开机自启：走系统 `SMAppService` 登录项，不写 `LaunchAgents` plist、不申请额外权限。
/// 默认关闭；只有用户在菜单栏勾选才注册，注册后在系统「登录项与扩展」里同样可见可关。
enum LoginItemController {
    static var isEnabled: Bool {
        let status = SMAppService.mainApp.status
        return status == .enabled || status == .requiresApproval
    }

    static func register() throws {
        try SMAppService.mainApp.register()
    }

    static func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}
