import Engine from '../util/Engine';

@Component
export struct Splash {
  @ObjectLink engine: Engine;

  aboutToAppear(): void {
    this.setup()
  }

  build() {
    Stack() {
      if (this.engine.error) {
        Column() {
          Text(this.engine.error)
            .padding({ bottom: 8 })
          Button() {
            SymbolGlyph($r('sys.symbol.arrow_clockwise'))
              .fontColor([Color.White])
          }
          .size({ width: '50', height: '50' })
          .type(ButtonType.Circle)
          .onClick(() => {
            this.setup()
          })
        }.size({ width: '70%', height: '70%' }).justifyContent(FlexAlign.Center)
      } else {
        LoadingProgress().height(50)
      }
    }
    .height('100%')
    .width('100%')
  }

  setup() {
    this.engine.init()
  }
}