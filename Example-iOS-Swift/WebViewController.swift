import UIKit
import WebKit
import Foundation

protocol WebViewDelegate {
    func avatarUrlCallback(url : String)
}

class WebViewController: UIViewController, WKScriptMessageHandler {
    

    var avatarUrlDelegate:WebViewDelegate?
    var webView: WKWebView!
    

    let source = """
            window.addEventListener('message', function(event){
                const json = parse(event)

                if (json?.source !== 'avaturn') {
                  return;
                }


                window.webkit.messageHandlers.iosListener.postMessage(event.data);


                function parse(event) {
                    try {
                        return JSON.parse(event.data)
                    } catch (error) {
                        return null
                    }
                };
            });
        """
    
    override func loadView(){
        
        let config = WKWebViewConfiguration()
        let script = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(script)
        config.userContentController.add(self, name: "iosListener")
        webView = WKWebView(frame: .zero, configuration: config)
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView.allowsBackForwardNavigationGestures = true
    }
        
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let body = message.body as? String{
            
            let jsonData = body.data(using: .utf8)
            
            let jsonDict = try? JSONSerialization.jsonObject(
                with: jsonData!,
                options: []
            ) as? NSDictionary
            
            
            if jsonDict?["eventName"] as! String != "v2.avatar.exported" {
                return;
            }
            
            guard let data = jsonDict?["data"] as? NSDictionary else {
                print("empty data")
                return
            }
            
            
            guard let url_type = data["urlType"] as? String else {
                print("empty url type")
                return
            }
            guard let url = data["url"] as? String else {
                print("empty url")
                return
            }
            
            if url_type == "httpURL" {
                let alert = UIAlertController(title: "Received http URL for glb file", message: url, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                present(alert, animated: true, completion: nil)
            } else {
                guard let glb_bytes_string = url.components(separatedBy: ",").last else {
                    print("empty glb bytes")
                    return
                }
                
                guard let glb_bytes = Data(base64Encoded: glb_bytes_string, options: .ignoreUnknownCharacters) else {
                    print("empty glb bytes data")
                    return
                }
                let alert = UIAlertController(title: "Received data URL for glb file", message: String(format: "Glb file has %.2f Mb size", glb_bytes.megabytes), preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func reloadPage(clearHistory : Bool){
        let url = URL(string: "https://demo.avaturn.dev/")! // Replace with your own project URL
        if(clearHistory){
            WebCacheCleaner.clean()
        }
        webView.load(URLRequest(url: url))
    }

    func setCallback(delegate: WebViewDelegate){
        avatarUrlDelegate = delegate
    }
    

}

extension Data {

    var bytes: Int64 {
        .init(self.count)
    }

    public var kilobytes: Double {
        return Double(bytes) / 1_024
    }

    public var megabytes: Double {
        return kilobytes / 1_024
    }

}
