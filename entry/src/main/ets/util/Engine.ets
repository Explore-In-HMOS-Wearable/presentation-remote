import { wearEngine } from '@kit.WearEngine'
import { util } from '@kit.ArkTS';
import { Presentation } from '../model/Presentation';

@Observed
export default class Engine {
  private connectionError: Error = new Error('Connection failed, make sure the app is opened in the target device')
  private bundleName: string = '' // TODO: put mobile app bundle id
  private fingerprint: string = '' // TODO: put mobile app fingerprint
  private deviceClient: wearEngine.DeviceClient
  private targetDevice: wearEngine.Device | undefined = undefined;
  private hasApp = false
  private p2pClient: wearEngine.P2pClient
  private textEncoder: util.TextEncoder = new util.TextEncoder
  private textDecoder: util.TextDecoder = new util.TextDecoder
  // state
  initialized = false
  running = false
  error: string | undefined = undefined
  // data
  presentation: Presentation | null = null

  constructor(context: Context) {
    this.deviceClient = wearEngine.getDeviceClient(context)
    this.p2pClient = wearEngine.getP2pClient(context)
  }

  private async setDevice() {
    try {
      let devices = await this.deviceClient.getConnectedDevices()
      console.info(`Number of connected device ${devices.length}`)

      if (devices.length === 0) {
        this.error = 'No device is connected.'
        return
      }

      this.targetDevice = devices[0]
      let osCategory: wearEngine.OsCategory | undefined = this.targetDevice.osCategory;
      console.info(`The osCategory of target device is ${osCategory}`)
    } catch (error) {
      console.error(`setTargetDevice error: ${error.code}, ${error.message}`);
      this.error = 'Unknown error occurred, please try again later.'
    }
  }


  private async checkApp() {
    if (this.targetDevice) {
      try {
        // Check whether the specified app has been installed on the peer device.
        this.hasApp = await this.p2pClient.isRemoteAppInstalled(this.targetDevice.randomId, this.bundleName)
        console.info(`checkApp result: ${this.hasApp}`)

        if (!this.hasApp) {
          this.error = 'PresentationRemote is not installed on the phone.'
        }

      } catch (error) {
        console.error(`checkApp error: ${error.code}, ${error.message}`);
        this.error = 'Unknown error occurred, please try again later.'
      }

    } else {
      console.error('First use `setDevice`!')
    }
  }

  private async setReceiver() {
    if (this.targetDevice && this.hasApp) {
      try {
        let callback = (p2pMessage: wearEngine.P2pMessage) => {
          this.parseMessage(p2pMessage.content)
        }

        let appInfo: wearEngine.AppInfo = {
          bundleName: this.bundleName,
          fingerprint: this.fingerprint
        }

        let appParam: wearEngine.P2pAppParam = {
          remoteApp: appInfo
        }

        await this.p2pClient.registerMessageReceiver(this.targetDevice.randomId, appParam, callback)

        console.info('setReceiver done');
      } catch (error) {
        console.error(`setReceiver error: ${error.code}, ${error.message}`);
        this.error = 'Unknown error occurred, please try again later.'
      }
    } else {
      console.error('First use `setDevice` and install app to target device')
    }
  }

  private async askPresentation() {
    if (this.targetDevice && this.hasApp) {
      try {
        let appInfo: wearEngine.AppInfo = {
          bundleName: this.bundleName,
          fingerprint: this.fingerprint
        }

        let appParam: wearEngine.P2pAppParam = {
          remoteApp: appInfo
        }

        let messageContent: string = 'hasPresentation';

        let message: wearEngine.P2pMessage = {
          content: this.textEncoder.encodeInto(messageContent)
        }

        let res = await this.p2pClient.sendMessage(this.targetDevice.randomId, appParam, message)
        console.info(`askPresentation result: ${JSON.stringify(res)}`)
      } catch (error) {
        console.error(`askPresentation error: ${error.code}, ${error.message}`);
        if (error === this.connectionError) {
          this.error = error.message
        } else {
          this.error = 'Unknown error occurred, please try again later.'
        }
      }
    } else {
      console.error('First use `setDevice` and install app to target device')
    }
  }

  async sendCommand(command: string) {
    if (this.targetDevice && this.hasApp) {
      try {
        let appInfo: wearEngine.AppInfo = {
          bundleName: this.bundleName,
          fingerprint: this.fingerprint
        }

        let appParam: wearEngine.P2pAppParam = {
          remoteApp: appInfo
        }


        let message: wearEngine.P2pMessage = {
          content: this.textEncoder.encodeInto(command)
        }

        let res = await this.p2pClient.sendMessage(this.targetDevice.randomId, appParam, message)
        console.info(`sendCommand result: ${JSON.stringify(res)}`)
      } catch (error) {
        console.error(`sendCommand error: ${error.code}, ${error.message}`);
        if (error === this.connectionError) {
          this.error = error.message
        } else {
          this.error = 'Unknown error occurred, please try again later.'
        }
      }
    } else {
      console.error('First use `setDevice` and install app to target device')
    }
  }

  async init() {
    this.running = true
    this.error = undefined
    if (this.targetDevice === undefined) {
      await this.setDevice()
    }
    if (!this.error && !this.hasApp) {
      await this.checkApp()
    }
    if (!this.error && this.hasApp) {
      await this.setReceiver()
    }
    this.running = false
    this.initialized = this.error === undefined

    if (this.initialized) {
      await this.askPresentation()
    }
  }

  private parseMessage(msg: Uint8Array) {
    const str = this.textDecoder.decodeToString(msg)
    const index = str.indexOf(' ')
    const code = parseInt(str.substring(0, index))
    console.info('code', code)
    const data = str.substring(index + 1)
    console.info(`|${data}|`);

    if (code === WEM.presentation) {
      try {
        this.presentation = JSON.parse(data)
        console.info('presentation', this.presentation)
      } catch (e) {
        console.error('parse error', e, JSON.stringify(e))
      }

    }
  }
}

/// Wear Engine Message
enum WEM {
  presentation,
}