import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Ajouté

class MedtrumMonitor extends StatefulWidget {
  final String targetUrl;
  final bool enableZoom;

  const MedtrumMonitor({
    super.key,
    this.targetUrl = "https://my.glookoxt.com/dashboard",
    this.enableZoom = false,
  });

  @override
  State<MedtrumMonitor> createState() => _MedtrumMonitorState();
}

class _MedtrumMonitorState extends State<MedtrumMonitor> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialisation du Controller WebView
    _controller = WebViewController();

    // Configuration conditionnelle : On évite ce qui crash sur le Web
    if (!kIsWeb) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000));
    }

    _controller
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // 2. INJECTION CSS/JS (Uniquement sur Mobile, bloqué par CORS sur Web)
            if (!kIsWeb) {
              _injectCleanerScript();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.targetUrl));
  }

  /// Cette fonction injecte du CSS via JavaScript pour masquer
  /// l'interface native du site (headers, footers) et ne garder que le contenu.
  void _injectCleanerScript() {
    // Note: Les sélecteurs ci-dessous sont génériques.
    // L'utilisateur devra peut-être inspecter le site réel pour trouver les IDs exacts.
    const String cssInjection = """
      (function() {
        // Liste des éléments à supprimer (sélecteurs CSS)
        var selectorsToRemove = [
          'header', 
          'footer', 
          'nav', 
          '.navbar', 
          '.sidebar', 
          '#sidebar', 
          '.cookie-banner', 
          '.cookie-consent',
          '.ads',
          '.banner',
          '.top-bar'
        ];

        selectorsToRemove.forEach(function(selector) {
          var elements = document.querySelectorAll(selector);
          elements.forEach(function(el) {
            el.style.display = 'none !important';
            el.style.visibility = 'hidden';
          });
        });

        // Tenter d'ajuster le contenu principal pour qu'il prenne toute la place
        var mainContent = document.querySelector('main') || document.querySelector('#main') || document.querySelector('.content') || document.body;
        if(mainContent) {
          mainContent.style.margin = '0';
          mainContent.style.padding = '0';
          mainContent.style.width = '100%';
        }
      })();
    """;
    
    _controller.runJavaScript(cssInjection);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias, // Important pour que la WebView respecte les bords arrondis
      child: Stack(
        children: [
          // La WebView elle-même
          WebViewWidget(controller: _controller),

          // Indicateur de chargement (Barre de progression)
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: Colors.transparent,
                color: Colors.blueAccent, // Ou utiliser AppColors.primary
              ),
            ),
            
          // Gestion d'erreur simple
          if (_hasError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  const Text("Erreur de chargement Medtrum"),
                  TextButton(
                    onPressed: () => _controller.reload(),
                    child: const Text("Réessayer"),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
