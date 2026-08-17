// pages/RegisterPage.ets
import { HttpResponseResult } from '../model/HttpResponseResult';
import { RegisterRequest, RegisterResponseData } from '../model/AuthModels';
import HttpUtil from '../../http/HttpUtil';

@Entry
@Component
struct RegisterPage {
  @State username: string = ""
  @State password: string = ""
  @State confirmPassword: string = ""
  @State nickname: string = ""
  @State email: string = ""
  @State phone: string = ""
  @State isAgree: boolean = false
  @State isLoading: boolean = false

  build() {
    Column() {
      // 返回按钮和标题
      Row() {
        SymbolGlyph($r("sys.symbol.left_turn"))
          .fontSize(24)
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
        Text("注册")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Row().width(24)
      }
      .width('90%')
      .margin({ top: 20, bottom: 30 })

      // 表单
      Column() {
        // 用户名
        this.buildInputRow("用户名", this.username, "请输入用户名", (value: string) => {
          this.username = value
        })

        // 昵称
        this.buildInputRow("昵称", this.nickname, "请输入昵称（可选）", (value: string) => {
          this.nickname = value
        })

        // 密码
        this.buildInputRow("密码", this.password, "请输入密码（至少6位）", (value: string) => {
          this.password = value
        }, true)

        // 确认密码
        this.buildInputRow("确认密码", this.confirmPassword, "请再次输入密码", (value: string) => {
          this.confirmPassword = value
        }, true)

        // 邮箱
        this.buildInputRow("邮箱", this.email, "请输入邮箱（可选）", (value: string) => {
          this.email = value
        })

        // 手机号
        this.buildInputRow("手机号", this.phone, "请输入手机号（可选）", (value: string) => {
          this.phone = value
        })
      }
      .width('85%')

      // 同意条款
      Row() {
        Checkbox()
          .select(this.isAgree)
          .onChange((value: boolean) => {
            this.isAgree = value
          })
        Text("同意")
          .fontSize(14)
          .fontColor("#666666")
        Text("用户条例")
          .fontSize(14)
          .fontColor("#1890ff")
      }
      .width('85%')
      .justifyContent(FlexAlign.Start)
      .margin({ top: 20, bottom: 30 })

      // 注册按钮
      Button(this.isLoading ? "注册中..." : "注册")
        .width('85%')
        .fontSize(18)
        .enabled(!this.isLoading && this.isAgree)
        .onClick(() => {
          this.handleRegister()
        })

      // 跳转到登录
      Row() {
        Text("已有账号？")
          .fontSize(14)
          .fontColor("#666666")
        Text("立即登录")
          .fontSize(14)
          .fontColor("#1890ff")
          .onClick(() => {
            this.getUIContext().getRouter().back()
          })
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor("#fff1efef")
  }

  @Builder
  buildInputRow(label: string, value: string, placeholder: string, onChange: (value: string) => void, isPassword: boolean = false) {
    Column() {
      Row() {
        Text(label)
          .fontSize(16)
          .width(70)
          .fontWeight(FontWeight.Medium)
        TextInput({ text: value, placeholder: placeholder })
          .layoutWeight(1)
          .fontSize(16)
          .type(isPassword ? InputType.Password : InputType.Normal)
          .onChange(onChange)
      }
      .width('100%')
      .margin({ bottom: 16 })
    }
  }

  async handleRegister() {
    // 校验
    if (!this.username.trim()) {
      this.getUIContext().getPromptAction().showToast({
        message: "请输入用户名",
        bottom: "40%"
      })
      return
    }

    if (this.username.length < 3) {
      this.getUIContext().getPromptAction().showToast({
        message: "用户名至少3位",
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

    if (this.password !== this.confirmPassword) {
      this.getUIContext().getPromptAction().showToast({
        message: "两次密码输入不一致",
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

    // 邮箱格式校验（如果有）
    if (this.email.trim()) {
      const emailRegex = /^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,6}$/
      if (!emailRegex.test(this.email.trim())) {
        this.getUIContext().getPromptAction().showToast({
          message: "请输入正确的邮箱格式",
          bottom: "40%"
        })
        return
      }
    }

    // 手机号格式校验（如果有）
    if (this.phone.trim()) {
      const phoneRegex = /^1[3-9]\d{9}$/
      if (!phoneRegex.test(this.phone.trim())) {
        this.getUIContext().getPromptAction().showToast({
          message: "请输入正确的手机号",
          bottom: "40%"
        })
        return
      }
    }

    this.isLoading = true

    try {
      // 使用 RegisterRequest 类型
      const registerData: RegisterRequest = {
        username: this.username.trim(),
        password: this.password.trim(),
        nickname: this.nickname.trim() || this.username.trim(),
        email: this.email.trim(),
        phone: this.phone.trim(),
        avatarUrl: "/uploads/avatar/default.jpg"
      }

      const result = await HttpUtil.post<HttpResponseResult<RegisterResponseData>>(
        "/user/account/register",
        registerData
      )

      if (result.code === 200) {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || "注册成功",
          bottom: "40%"
        })

        // 延迟返回登录页
        setTimeout(() => {
          this.getUIContext().getRouter().back()
        }, 1000)
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || "注册失败，请稍后重试",
          bottom: "40%"
        })
      }
    } catch (error) {
      console.error("注册异常:", error)
      this.getUIContext().getPromptAction().showToast({
        message: "网络异常，请稍后重试",
        bottom: "40%"
      })
    } finally {
      this.isLoading = false
    }
  }
}

export default RegisterPage