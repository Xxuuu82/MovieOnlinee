import httpUtil from "../http/HttpUtil"
import { UserAccount } from "../model/UserAccount"

interface BalanceResponse {
  code: number;
  message: string;
  data: null;
}

interface RechargeRequest {
  userId: number;
  balance: number;
}

interface BalanceData {
  id: number;
  userId: number;
  balance: number;
  createTime: string;
  updateTime: string;
}

interface BalanceInfoResponse {
  code: number;
  message: string;
  data: BalanceData;
}

@Component
export struct MyComponent {
  // ==========================================================
  // 用户信息
  // ==========================================================
  @StorageLink('userAccount')
  @Watch('onUserAccountChange')
  userAccount: UserAccount | null = null

  // ==========================================================
  // 🔥 接收父页面的刷新信号
  // ==========================================================
  @Prop
  @Watch('onRefreshKeyChange')
  refreshKey: number = 0

  @State balance: number = 0
  @State showRechargeDialog: boolean = false
  @State rechargeAmount: string = ''

  // ==========================================================
  // 页面第一次出现
  // ==========================================================
  aboutToAppear() {
    console.info('MyComponent 第一次出现')
    this.loadBalance()
  }

  // ==========================================================
  // 🔥 刷新信号变化时触发（任何场景回到页面都会触发）
  // ==========================================================
  onRefreshKeyChange() {
    console.info(
      '检测到刷新信号，重新获取余额，refreshKey:',
      this.refreshKey
    )
    this.loadBalance()
  }

  // ==========================================================
  // 🔥 用户信息发生变化
  // ==========================================================
  onUserAccountChange() {
    console.info(
      '用户信息发生变化:',
      this.userAccount ? '已登录' : '未登录'
    )

    if (this.userAccount) {
      this.loadBalance()
    } else {
      this.balance = 0
      this.showRechargeDialog = false
      this.rechargeAmount = ''
    }
  }

  // ==========================================================
  // 获取最新余额
  // ==========================================================
  async loadBalance() {
    if (!this.userAccount) {
      this.balance = 0
      return
    }

    try {
      const result = await httpUtil.get<BalanceInfoResponse>(
        `/user/balance/info?userId=${this.userAccount.id}`
      )

      if (result.code === 200 && result.data) {
        const newBalance = Number(result.data.balance)

        if (this.balance !== newBalance) {
          console.info(
            '余额变化:',
            this.balance,
            '->',
            newBalance
          )
        }

        this.balance = newBalance
      }
    } catch (error) {
      console.error('获取余额失败', error)
    }
  }

  // ==========================================================
  // 余额充值
  // ==========================================================
  async recharge(): Promise<void> {
    if (!this.userAccount) {
      this.getUIContext().getPromptAction().showToast({
        message: '请先登录'
      })
      return
    }

    const amount = Number(this.rechargeAmount)

    if (isNaN(amount) || amount <= 0) {
      this.getUIContext().getPromptAction().showToast({
        message: '请输入正确充值金额'
      })
      return
    }

    try {
      const request: RechargeRequest = {
        userId: this.userAccount.id,
        balance: amount
      }

      console.info(
        '发起充值请求:',
        JSON.stringify(request)
      )

      const result = await httpUtil.post<BalanceResponse>(
        '/user/balance/recharge',
        request
      )

      console.info(
        '充值接口返回:',
        JSON.stringify(result)
      )

      if (result.code === 200) {
        this.rechargeAmount = ''
        this.showRechargeDialog = false

        await this.loadBalance()

        this.getUIContext().getPromptAction().showToast({
          message:
          '充值成功！当前余额：¥' +
            this.balance.toFixed(2)
        })
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: result.message || '充值失败'
        })
      }

    } catch (error) {
      console.error('充值失败:', error)

      this.getUIContext().getPromptAction().showToast({
        message: '充值失败，请稍后重试'
      })
    }
  }

  // ==========================================================
  // 跳转登录页面
  // ==========================================================
  goToLogin(): void {
    this.getUIContext().getRouter().pushUrl({
      url: 'pages/LoginPage'
    })
  }

  // ==========================================================
  // 跳转订单列表
  // ==========================================================
  goToOrderList(): void {
    if (!this.userAccount) {
      this.getUIContext().getPromptAction().showToast({
        message: "请先登录",
        bottom: "50%"
      })
      return
    }

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/OrderListPage'
    })
  }

  // ==========================================================
  // 点击收藏
  // ==========================================================
  goToFavorite(): void {
    if (!this.userAccount) {
      this.goToLogin()
      return
    }

    this.getUIContext().getRouter().pushUrl({
      url: 'pages/CinemaSaveList'
    })
  }

  // ==========================================================
  // 🔥 退出登录
  // ==========================================================
  logout(): void {
    console.info('开始退出登录')

    this.showRechargeDialog = false
    this.rechargeAmount = ''
    this.balance = 0

    AppStorage.delete('userAccount')
    AppStorage.delete('isLogin')

    this.userAccount = null

    console.info('退出登录完成')
  }

  // ==========================================================
  // 获取头像文字
  // ==========================================================
  getAvatarText(): string {
    if (this.userAccount?.nickname) {
      return this.userAccount.nickname.substring(0, 1)
    }

    if (this.userAccount?.username) {
      return this.userAccount.username.substring(0, 1)
    }

    return '我'
  }

  // ==========================================================
  // 获取头像 URL
  // ==========================================================
  getAvatarUrl(): string {
    if (!this.userAccount?.avatarUrl) {
      return ''
    }

    if (this.userAccount.avatarUrl.startsWith('http')) {
      return this.userAccount.avatarUrl
    }

    return httpUtil.BASE_URL + this.userAccount.avatarUrl
  }

  build() {
    Column() {

      Scroll() {
        Column() {

          // ==========================================================
          // 用户信息区域
          // ==========================================================
          if (this.userAccount) {

            Row() {

              if (this.userAccount.avatarUrl) {

                Image(this.getAvatarUrl())
                  .width(80)
                  .height(80)
                  .borderRadius(40)
                  .objectFit(ImageFit.Cover)

              } else {

                Column() {

                  Text(this.getAvatarText())
                    .fontSize(30)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#666666')

                }
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor('#EEEEEE')
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
              }

              Column() {

                Text(
                  this.userAccount.nickname ||
                    this.userAccount.username ||
                    '用户'
                )
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')

                Text(
                  this.userAccount.email ||
                    '未绑定邮箱'
                )
                  .fontSize(13)
                  .fontColor('#888888')
                  .margin({ top: 6 })

                Text(
                  this.userAccount.phone ||
                    '未绑定手机号'
                )
                  .fontSize(13)
                  .fontColor('#888888')
                  .margin({ top: 4 })

                Text(
                  '余额：¥' +
                    this.balance.toFixed(2)
                )
                  .fontSize(13)
                  .fontColor('#888888')
                  .margin({ top: 4 })

              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 14 })

            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: 24,
              bottom: 20
            })

          } else {

            // ========================================================
            // 🔥 未登录状态
            // ========================================================
            Row() {

              Column() {

                SymbolGlyph(
                  $r('sys.symbol.person_crop_circle_fill')
                )
                  .fontSize(50)
                  .fontColor(['#AAAAAA'])

              }
              .width(70)
              .height(70)
              .justifyContent(FlexAlign.Center)

              Column() {

                Text('未登录')
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')

                Text('登录后查看个人信息')
                  .fontSize(13)
                  .fontColor('#999999')
                  .margin({ top: 6 })

              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 14 })

              Button('登录')
                .width(60)
                .height(32)
                .fontSize(13)
                .fontColor('#FFFFFF')
                .backgroundColor('#1698CE')
                .borderRadius(16)
                .onClick(() => {
                  this.goToLogin()
                })

            }
            .width('100%')
            .padding({
              left: 24,
              right: 24,
              top: 24,
              bottom: 20
            })
          }

          // ==========================================================
          // 收藏 / 看过 / 评分
          // ==========================================================
          Row() {

            Column() {

              SymbolGlyph($r('sys.symbol.heart'))
                .fontSize(25)
                .fontColor(['#333333'])

              Text('收藏')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)
            .onClick(() => {
              this.goToFavorite()
            })

            Column() {

              SymbolGlyph($r('sys.symbol.template'))
                .fontSize(25)
                .fontColor(['#333333'])

              Text('看过')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)

            Column() {

              SymbolGlyph($r('sys.symbol.star'))
                .fontSize(25)
                .fontColor(['#333333'])

              Text('评分')
                .fontSize(14)
                .fontColor('#53B7AE')
                .fontWeight(FontWeight.Bold)
                .margin({ top: 6 })

            }
            .layoutWeight(1)

          }
          .width('calc(100% - 32vp)')
          .height(80)
          .margin({
            left: 16,
            right: 16
          })
          .border({
            width: 1,
            color: '#DDDDDD'
          })
          .borderRadius(14)
          .justifyContent(FlexAlign.Center)

          // ==========================================================
          // 菜单
          // ==========================================================
          this.MenuItem(
            '尊享会员',
            'person_crop_circle_fill_1'
          )

          this.MenuItem(
            '我的订单',
            'satellite_map',
            () => {
              this.goToOrderList()
            }
          )

          this.MenuItem(
            '优惠券',
            'heart_square_stack_fill'
          )

          this.MenuItem(
            '充值中心',
            'bolt',
            () => {
              this.loadBalance()
              this.showRechargeDialog = true
            }
          )

          this.MenuItem(
            '设置',
            'gearshape'
          )

          this.MenuItem(
            '帮助中心',
            'list_number'
          )

          // ==========================================================
          // 退出登录
          // ==========================================================
          if (this.userAccount) {

            Button('退出登录')
              .width('calc(100% - 64vp)')
              .height(40)
              .fontSize(14)
              .fontColor('#53AFC0')
              .backgroundColor('#FFFFFF')
              .border({
                width: 1,
                color: '#8CCED8'
              })
              .borderRadius(20)
              .margin({
                left: 32,
                right: 32,
                top: 18,
                bottom: 30
              })
              .onClick(() => {
                this.logout()
              })
          }

        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Off)

      // ==========================================================
      // 充值弹窗
      // ==========================================================
      if (this.showRechargeDialog) {

        Column() {

          Column() {

            Column() {

              Text('充值中心')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#222222')
                .margin({ top: 24 })

              Row() {

                Text('当前余额：')
                  .fontSize(15)
                  .fontColor('#888888')

                Text(
                  '¥' +
                    this.balance.toFixed(2)
                )
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF6B35')

              }
              .margin({ top: 12 })

              TextInput({
                placeholder: '请输入充值金额',
                text: this.rechargeAmount
              })
                .width('80%')
                .height(48)
                .margin({ top: 20 })
                .onChange((value: string) => {
                  this.rechargeAmount = value
                })
                .type(InputType.Number)
                .backgroundColor('#F5F5F5')
                .borderRadius(8)
                .fontSize(16)

              Text('充值金额需为整数')
                .fontSize(12)
                .fontColor('#CCCCCC')
                .margin({ top: 12 })

              Row() {

                Button('取消')
                  .width('35%')
                  .height(44)
                  .backgroundColor('#F0F0F0')
                  .fontColor('#666666')
                  .borderRadius(22)
                  .onClick(() => {
                    this.showRechargeDialog = false
                    this.rechargeAmount = ''
                  })

                Button('确认充值')
                  .width('35%')
                  .height(44)
                  .backgroundColor('#1698CE')
                  .fontColor('#FFFFFF')
                  .borderRadius(22)
                  .onClick(() => {
                    this.recharge()
                  })

              }
              .width('80%')
              .justifyContent(FlexAlign.SpaceAround)
              .margin({
                top: 16,
                bottom: 24
              })

            }
            .width('85%')
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .padding({
              top: 10,
              bottom: 10
            })

          }
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.showRechargeDialog = false
            this.rechargeAmount = ''
          })

        }
        .width('100%')
        .height('100%')
        .position({
          x: 0,
          y: 0
        })
        .zIndex(100)
      }

    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  // ==========================================================
  // 菜单 Builder
  // ==========================================================
  @Builder
  MenuItem(
    title: string,
    iconName: string,
    onClick?: () => void
  ) {

    Column() {

      Row() {

        if (iconName === 'person_crop_circle_fill_1') {

          SymbolGlyph(
            $r('sys.symbol.person_crop_circle_fill_1')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        } else if (iconName === 'satellite_map') {

          SymbolGlyph(
            $r('sys.symbol.satellite_map')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        } else if (iconName === 'heart_square_stack_fill') {

          SymbolGlyph(
            $r('sys.symbol.heart_square_stack_fill')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        } else if (iconName === 'bolt') {

          SymbolGlyph(
            $r('sys.symbol.bolt')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        } else if (iconName === 'gearshape') {

          SymbolGlyph(
            $r('sys.symbol.gearshape')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })

        } else if (iconName === 'list_number') {

          SymbolGlyph(
            $r('sys.symbol.list_number')
          )
            .fontSize(21)
            .fontColor(['#444444'])
            .margin({ left: 16 })
        }

        Text(title)
          .fontSize(15)
          .fontColor('#444444')
          .layoutWeight(1)
          .margin({ left: 14 })

        SymbolGlyph(
          $r('sys.symbol.chevron_right')
        )
          .fontSize(16)
          .fontColor(['#999999'])
          .margin({ right: 14 })

      }
      .width('100%')
      .height(55)
      .onClick(() => {
        if (onClick) {
          onClick()
        }
      })

      Divider()
        .width('calc(100% - 32vp)')
        .color('#DDDDDD')

    }
    .width('100%')
  }
}