import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GLBAvatar extends StatefulWidget {
  final bool isAnimating;
  final double size;

  const GLBAvatar({
    super.key,
    this.isAnimating = false,
    this.size = 60.0,
  });

  @override
  State<GLBAvatar> createState() => _GLBAvatarState();
}

class _GLBAvatarState extends State<GLBAvatar> {
  bool _hasError = false;
  WebViewController? _webViewController;
  bool _isWebViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() async {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              print('GLBAvatar: 3D Model loaded successfully');
              setState(() {
                _isWebViewInitialized = true;
              });
            },
            onWebResourceError: (WebResourceError error) {
              print('GLBAvatar error: ${error.description}');
              setState(() {
                _hasError = true;
              });
            },
          ),
        );
      
      await _webViewController!.loadHtmlString(_getHtmlContent());
    } catch (e) {
      print('Error initializing GLBAvatar: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  String _getHtmlContent() {
    print('GLBAvatar: Loading Ready Player Me Avatar');
    print('GLBAvatar: Animation enabled: ${widget.isAnimating}');
    
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3D Avatar</title>
    <script type="module" src="https://unpkg.com/@google/model-viewer/dist/model-viewer.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            background: transparent;
            overflow: hidden;
            width: 100vw;
            height: 100vh;
        }
        model-viewer {
            width: 100%;
            height: 100%;
            background: transparent !important;
            --poster-color: transparent;
            --progress-bar-color: transparent;
            --progress-mask: transparent;
            --progress-bar: transparent;
            --model-viewer-background-color: transparent;
            --model-viewer-poster-color: transparent;
            --model-viewer-ui-color: transparent;
            --model-viewer-ui-overlay: transparent;
        }
        
        model-viewer::part(default-progress-bar) {
            display: none;
        }
        
        model-viewer::part(default-progress-mask) {
            display: none;
        }
        .loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            color: white;
            font-family: Arial, sans-serif;
            font-size: 12px;
            z-index: 10;
        }
    </style>
</head>
<body>
    <model-viewer
        src="https://models.readyplayer.me/6919bd4d28f4be8b0cf728e1.glb"
        alt="Ready Player Me Avatar"
        auto-rotate="${widget.isAnimating ? 'true' : 'false'}"
        camera-controls="false"
        disable-zoom
        disable-pan
        disable-tap
        interaction-prompt="none"
        loading="eager"
        camera-orbit="0deg 75deg 1.5m"
        field-of-view="30deg"
        autoplay="${widget.isAnimating ? 'true' : 'false'}"
        animation-name="Idle"
        style="width: 100%; height: 100%; background: transparent;">
        
        <div class="loading" slot="poster">
            Loading 3D Avatar...
        </div>
    </model-viewer>
    
    <script>
        console.log('GLBAvatar: Loading Ready Player Me Avatar...');
        console.log('GLBAvatar: Animation enabled: ${widget.isAnimating}');
        
        // Wait for model-viewer to be ready
        document.addEventListener('DOMContentLoaded', () => {
            const modelViewer = document.querySelector('model-viewer');
            
            if (modelViewer) {
                console.log('GLBAvatar: Model-viewer element found');
                
                // Listen for model load
                modelViewer.addEventListener('load', () => {
                    console.log('GLBAvatar: Ready Player Me Avatar loaded successfully');
                    const loading = document.querySelector('.loading');
                    if (loading) loading.style.display = 'none';
                    
                    // Enable animations
                    if (${widget.isAnimating}) {
                        console.log('GLBAvatar: Enabling animations');
                        modelViewer.autoRotate = true;
                        modelViewer.autoplay = true;
                        
                        // Check available animations
                        console.log('GLBAvatar: Available animations:', modelViewer.availableAnimations);
                        console.log('GLBAvatar: Current animation:', modelViewer.animationName);
                        
                        // Try to play specific animations
                        try {
                            if (modelViewer.availableAnimations && modelViewer.availableAnimations.length > 0) {
                                console.log('GLBAvatar: Playing animation:', modelViewer.availableAnimations[0]);
                                modelViewer.animationName = modelViewer.availableAnimations[0];
                            }
                            modelViewer.play();
                            console.log('GLBAvatar: Animation started');
                        } catch (e) {
                            console.log('GLBAvatar: Animation play failed:', e);
                        }
                    }
                });
                
                // Listen for errors
                modelViewer.addEventListener('error', (event) => {
                    console.error('GLBAvatar: Error loading Ready Player Me Avatar:', event);
                });
                
                // Listen for animation events
                modelViewer.addEventListener('animation-finished', (event) => {
                    console.log('GLBAvatar: Animation finished:', event.detail);
                });
                
                // Force load the model
                modelViewer.load();
            } else {
                console.error('GLBAvatar: Model-viewer element not found');
            }
        });
    </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        children: [
          // 3D Model WebView
          if (!_hasError && _webViewController != null)
            SizedBox(
              width: widget.size,
              height: widget.size,
              child: WebViewWidget(controller: _webViewController!),
            )
          else
            // Fallback tanpa background bulat
            Container(
              width: widget.size,
              height: widget.size,
              child: Center(
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.blue,
                  size: widget.size * 0.6,
                ),
              ),
            ),
          
          // Loading indicator overlay
          if (!_isWebViewInitialized && !_hasError)
            Container(
              width: widget.size,
              height: widget.size,
              color: Colors.black.withOpacity(0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: widget.size * 0.3,
                      height: widget.size * 0.3,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    if (widget.size > 50) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Loading 3D...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}