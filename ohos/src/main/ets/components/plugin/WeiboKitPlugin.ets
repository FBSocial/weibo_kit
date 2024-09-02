import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import {
  WBAPI,
  AuthInfo,
  SdkListener,
  WeiboMultiMessage,
  WbASListener,
  UiError,
  TextObject,
  MultiImageObject
} from 'core';
import { bundleManager, common, contextConstant } from '@kit.AbilityKit';
import { ArrayList } from '@kit.ArkTS';
import { fileUri } from '@kit.CoreFileKit';

// import { bundleManager } from '@kit.AbilityKit';

/** WeiboKitPlugin **/
export default class WeiboKitPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  public TAG = "WeiboKitPlugin";

  constructor() {
  }

  getUniqueClassName(): string {
    return "WeiboKitPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "v7lin.github.io/weibo_kit");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    console.log(this.TAG, "onMethodCall: " + call.method);
    if (call.method == "getPlatformVersion") {
      result.success("OpenHarmony ^ ^ ")
    } else if ("registerApp" == call.method) {
      let appKey = call.argument("appKey") as string;
      let scope = call.argument("scope") as string;
      let redirectUrl = call.argument("redirectUrl") as string;
      let context = getContext(this) as common.UIAbilityContext
      let authInfo = new AuthInfo(context, appKey, redirectUrl, scope, 'EntryAbility');
      let listener: SdkListener = {
        onInitSuccess: () => {
          console.log(this.TAG, "registerApp success");
        },
        onInitFail: (error: Error) => {
          console.log(this.TAG, "registerApp failed: " + error.message);
        }
      };
      WBAPI.getInstance().registerApp(authInfo, listener);
      result.success(null);
    } else if ("isInstalled" == call.method) {
      try {
        let canOpen = bundleManager.canOpenLink('sinaweibo://');
        console.log(this.TAG, 'isInstalled -- canOpen: ' + canOpen);
        result.success(canOpen);
      } catch (err) {
        result.success(false);
      }
    } else if ("shareText" == call.method || "shareMultiImage" == call.method || "shareWebpage" == call.method) {
      let message: WeiboMultiMessage = new WeiboMultiMessage();
      let context = getContext(this) as common.UIAbilityContext
      let listener: WbASListener = {
        onComplete: () => {
          console.log(this.TAG, "分享成功");
        },
        onError: (error: UiError) => {
          console.log(this.TAG, "分享出错" + error.errorMessage);
        },
        onCancel: () => {
          console.log(this.TAG, "分享取消");
        }
      };
      if ("shareText" == call.method) {
        let text = call.argument("text") as string;
        let textObject = new TextObject();
        textObject.text = text;
        message.textObject = textObject;
      } else if ("shareMultiImage" == call.method) {
        // console.log(this.TAG, "imageUris type: " + uris.toString() + " " + uris);
        let imageUris = call.argument("imageUris") as string[];
        let filePath = imageUris[0];
        console.log(this.TAG, "multiImage filePath: " + filePath);
        if (filePath.startsWith("file://")) {
          filePath = filePath.replace("file://", '');
        }
        console.log(this.TAG, "multiImage filePath -- " + filePath);
        let multiImage = new MultiImageObject();
        try {
          let uris = new ArrayList<string>();
          uris.add(fileUri.getUriFromPath(filePath));
          // uris.add(fileUri.getUriFromPath(this.getCacheFile(getContext()) + 'ddd.jpg'));
          console.log(this.TAG, "multiImage value: " + uris[0]);
          multiImage.uriStrs = uris.convertToArray();
        } catch (e) {
          console.log(this.TAG, "multiImage error: " + e.message);
        }
        message.multiImageObject = multiImage;
      } else if ("shareWebpage" == call.method) {
        let title = call.argument("title") as string;
        let description = call.argument("description") as string;
        let webpageUrl = call.argument("webpageUrl") as string;
        console.log(this.TAG, "multiImage webpageUrl: " + webpageUrl + " title:" + title);
        let textObject = new TextObject();
        let text = '';
        if (title != '') {
          text += title + "\n";
        }
        if (description != '') {
          text += description + "\n";
        }
        text += webpageUrl;
        textObject.text = text;
        message.textObject = textObject;
      }
      WBAPI.getInstance().shareMessage(context, message, listener);
      result.success(null);
    } else {
      result.notImplemented();
    }
    console.log(this.TAG, "onMethodCall: " + call.method + " -- end");
  }

  getCacheFile(context: Context): string {
    let application = context.getApplicationContext();
    if (application.area === contextConstant.AreaMode.EL2) { // 获取area
      application.area = contextConstant.AreaMode.EL1; // 修改area
    }
    let path: string = application.cacheDir;
    return path;
  }
}