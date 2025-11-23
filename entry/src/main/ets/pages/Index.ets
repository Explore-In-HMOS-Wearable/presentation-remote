import { Splash } from '../components/Splash';
import Engine from '../util/Engine';

@Entry
@Component
struct Index {
  @State engine: Engine = new Engine(this.getUIContext().getHostContext() as Context)

  build() {
    if (!this.engine.initialized) {
      Splash({ engine: this.engine })
    } else {
      Stack() {
        if (this.engine.presentation) {
          Column() {
            Text(`${this.engine.presentation.current} / ${this.engine.presentation.total}`)
              .layoutWeight(1)
            Row() {
              Button() {
                SymbolGlyph($r('sys.symbol.chevron_left'))
                  .fontColor([Color.White])
              }
              .type(ButtonType.Circle)
              .enabled(this.engine.presentation.current !== 1)
              .height('100%')
              .aspectRatio(1)
              .onClick(() => {
                this.engine.sendCommand('previous')
              })

              Button() {
                SymbolGlyph($r('sys.symbol.chevron_right'))
                  .fontColor([Color.White])
              }
              .type(ButtonType.Circle)
              .enabled(this.engine.presentation.current !== this.engine.presentation.total)
              .height('100%')
              .aspectRatio(1)
              .onClick(() => {
                this.engine.sendCommand('next')
              })
            }
            .height('30%')
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)

            Button() {
              SymbolGlyph($r('sys.symbol.xmark'))
                .fontColor([Color.White])
            }
            .backgroundColor(Color.Red)
            .type(ButtonType.Circle)
            .height('30%')
            .aspectRatio(1)
            .onClick(() => {
              this.engine.sendCommand('close')
            })
          }.size({ width: '70%', height: '70%' }).justifyContent(FlexAlign.Center)
        } else {
          Column() {
            Text(`Open PresentationRemote on your phone and start your presentation.`)
              .onClick(() => {
                console.info('eng pre', this.engine.presentation);
              })
          }.size({ width: '70%', height: '70%' }).justifyContent(FlexAlign.Center)
        }
      }
      .height('100%')
      .width('100%')
    }
  }
}