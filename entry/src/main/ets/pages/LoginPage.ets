import HttpUtil from '../http/HttpUtil';
import { UserAccount } from '../model/UserAccount';
import { HttpResponseResult } from '../model/HttpResponseResult';

interface LoginRequest {
  username: string;
  password: string;
}

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State errorMessage: string = '';

  /**
   * 用户登录
   */
  async login(): Promise<void> {
    const username: string = this.username.trim();
    const password: string = this.password;

    // ==========================
    // 基础校验
    // ==========================

    if (!username) {
      this.errorMessage = '请输入用户名';
      return;
    }

    if (!password) {
      this.errorMessage = '请输入密码';
      return;
    }

    if (password.length < 6) {
      this.errorMessage = '密码长度不能少于6位';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // ==========================
      // 构造登录参数
      // ==========================

      const requestData: LoginRequest = {
        username: username,
        password: password
      };

      console.info('开始登录，用户名:', username);

      // ==========================
      // 调用登录接口
      // ==========================

      const response: HttpResponseResult<UserAccount> =
        await HttpUtil.post<HttpResponseResult<UserAccount>>(
          '/user/account/login',
          requestData
        );

      console.info(
        '登录接口返回:',
        JSON.stringify(response)
      );

      // ==========================
      // 登录成功
      // ==========================

      if (response.code === 200 && response.data) {
        const account: UserAccount = response.data;

        console.info(
          '登录成功，用户ID:',
          account.id
        );

        console.info(
          '登录成功，用户名:',
          account.username || ''
        );

        // ==================================================
        // 关键：
        // 不再把 UserAccount 转成 JSON 字符串保存
        // 直接保存 UserAccount 对象
        //
        // MyComponent 使用 @StorageLink 监听这个数据
        // 登录成功后会自动刷新
        // ==================================================

        AppStorage.setOrCreate<UserAccount>(
          'userAccount',
          account
        );

        // 保存登录状态
        AppStorage.setOrCreate<boolean>(
          'isLogin',
          true
        );

        console.info('当前登录用户信息已经保存到 AppStorage');

        // ==========================
        // 返回上一页
        // ==========================

        this.getUIContext()
          .getRouter()
          .back();

      } else {
        // ==========================
        // 登录失败
        // ==========================

        this.errorMessage =
          response.message || '用户名或密码错误';

        console.error(
          '登录失败:',
          response.message || '用户名或密码错误'
        );
      }

    } catch (error) {
      console.error(
        '登录请求异常:',
        JSON.stringify(error)
      );

      this.errorMessage = '网络异常，请稍后重试';

    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {

      // ================================
      // 顶部
      // ================================

      Column() {

        SymbolGlyph(
          $r('sys.symbol.person_crop_circle_fill')
        )
          .fontSize(60)
          .fontColor(['#1698CE'])
          .margin({ bottom: 16 })

        Text('MovieOnline')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#222222')

        Text('登录后享受完整服务')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ top: 8 })

      }
      .width('100%')
      .margin({
        top: 70,
        bottom: 45
      })


      // ================================
      // 用户名
      // ================================

      Row() {

        SymbolGlyph(
          $r('sys.symbol.person')
        )
          .fontSize(21)
          .fontColor(['#888888'])
          .margin({
            left: 14,
            right: 10
          })

        TextInput({
          placeholder: '请输入用户名',
          text: this.username
        })
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ right: 12 })
          .onChange((value: string) => {
            this.username = value;
            this.errorMessage = '';
          })

      }
      .width('100%')
      .height(48)
      .margin({ bottom: 15 })


      // ================================
      // 密码
      // ================================

      Row() {

        SymbolGlyph(
          $r('sys.symbol.lock')
        )
          .fontSize(21)
          .fontColor(['#888888'])
          .margin({
            left: 14,
            right: 10
          })

        TextInput({
          placeholder: '请输入密码',
          text: this.password
        })
          .type(InputType.Password)
          .layoutWeight(1)
          .height(48)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ right: 12 })
          .onChange((value: string) => {
            this.password = value;
            this.errorMessage = '';
          })

      }
      .width('100%')
      .height(48)


      // ================================
      // 错误信息
      // ================================

      if (this.errorMessage) {

        Text(this.errorMessage)
          .width('100%')
          .fontSize(13)
          .fontColor('#FF5A5A')
          .margin({ top: 10 })

      }


      // ================================
      // 登录按钮
      // ================================

      Button(
        this.isLoading ? '登录中...' : '登录'
      )
        .width('82%')
        .height(48)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .backgroundColor('#1698CE')
        .borderRadius(24)
        .margin({ top: 28 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.login();
        })


      // ================================
      // 注册
      // ================================

      Row() {

        Text('还没有账号？')
          .fontSize(14)
          .fontColor('#999999')

        Text('立即注册')
          .fontSize(14)
          .fontColor('#1698CE')
          .fontWeight(FontWeight.Bold)
          .margin({ left: 6 })
          .onClick(() => {
            console.info('注册功能暂未实现');
          })

      }
      .margin({ top: 25 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
    .padding({
      left: 30,
      right: 30,
      bottom: 40
    })
  }
}