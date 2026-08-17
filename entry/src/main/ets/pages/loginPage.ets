
import { HttpResponseResult } from '../model/HttpResponseResult';
import { UserAccount } from '../model/UserAccount';
import { LoginRequest, LoginResponseData } from '../model/AuthModels';
import httpUtil from '../http/HttpUtil';

@Entry
@Component
struct LoginPage {
  @State account: string = ""
  @State password: string = ""
  @State isAgree: boolean = false
  @State isLoading: boolean = false
  @StorageLink("userAccount")
  userAccount: UserAccount | undefined = undefined

  build() {
    Column() {
      // Logo图片
      Image($r("app.media.icon"))
        .width(80)
        .height(80)
        .margin({ bottom: 16 })

      //标题
      Text("白鹭影院")
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 40 })

      //账号输入行
      Row() {
        Text("账号")
          .fontSize(16)
          .width(60)
        TextInput({ text: this.account, placeholder: "请输入账号" })
          .layoutWeight(1)
          .fontSize(16)
          .onChange((value: string) => {
            this.account = value
          })
      }
      .width('85%')
      .margin({ bottom: 20 })

      //密码输入行
      Row() {
        Text("密码")
          .fontSize(16)
          .width(60)
        TextInput({ text: this.password, placeholder: "请输入密码" })
          .layoutWeight(1)
          .fontSize(16)
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value
          })
      }
      .width('85%')
      .margin({ bottom: 12 })

      //勾选框左对齐，忘记密码右对齐，同行
      Row() {
        Row() {
          Checkbox()
            .select(this.isAgree)
            .onChange((value: boolean) => {
              this.isAgree = value
            })
          Text("同意用户条例")
            .fontSize(12)
        }

        Text("忘记密码")
          .fontSize(12)
          .fontColor("#1890ff")
      }
      .width('85%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 8 })

      Row() {
        Text("没有账号？")
          .fontSize(12)
          .fontColor("#666666")
        Text("立即注册")
          .fontSize(12)
          .fontColor("#1890ff")
          .onClick(() => {
            this.getUIContext().getRouter().pushUrl({
              url: "pages/RegisterPage"
            })
          })
      }
      .width('85%')
      .justifyContent(FlexAlign.Start)
      .margin({ bottom: 30 })

      Button(this.isLoading ? "登录中..." : "登录")
        .width('85%')
        .fontSize(18)
        .enabled(!this.isLoading && this.isAgree)
        .onClick(() => {
          this.handleLogin()
        })

      // 错误提示
      if (!this.isAgree) {
        Text("请先同意用户条例")
          .fontSize(12)
          .fontColor("#ff4d4f")
          .margin({ top: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor("#fff1efef")
  }

  async handleLogin() {
    // 输入校验
    if (!this.account.trim()) {
      this.getUIContext().getPromptAction().showToast({
        message: "请输入账号",
        bottom: "40%"
      })
      return
    }

    if (!this.password.trim()) {
      this.getUIContext().getPromptAction().showToast({
        message: "请输入密码",
        bottom: "40%"
      })
      return
    }

    if (this.password.length < 6) {
      this.getUIContext().getPromptAction().showToast({
        message: "密码至少6位",
        bottom: "40%"
      })
      return
    }

    if (!this.isAgree) {
      this.getUIContext().getPromptAction().showToast({
        message: "请先同意用户条例",
        bottom: "40%"
      })
      return
    }

    this.isLoading = true

    try {
      // 使用 LoginRequest 类型
      const loginData: LoginRequest = {
        username: this.account.trim(),
        password: this.password.trim()
      }

      const result = await httpUtil.post<HttpResponseResult<LoginResponseData>>(
        "/user/account/login",
        loginData
      )

      if (result.code === 200 && result.data) {
        // 将登录响应数据转换为 UserAccount 格式
        const userAccount: UserAccount = {
          id: result.data.id,
          username: result.data.username,
          nickname: result.data.nickname,
          email: result.data.email,
          phone: result.data.phone,
          avatarUrl: result.data.avatarUrl,
          status: result.data.status
        }

        // 保存用户信息到AppStorage
        AppStorage.setOrCreate("userAccount", userAccount)
        this.userAccount = userAccount

        this.getUIContext().getPromptAction().showToast({
          message: "登录成功",
          bottom: "40%"
        })

        // 延迟返回上一页
        setTimeout(() => {
          this.getUIContext().getRouter().back()
        }, 500)
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || "登录失败，请检查账号密码",
          bottom: "40%"
        })
      }
    } catch (error) {
      console.error("登录异常:", error)
      this.getUIContext().getPromptAction().showToast({
        message: "网络异常，请稍后重试",
        bottom: "40%"
      })
    } finally {
      this.isLoading = false
    }
  }
}

export default LoginPage