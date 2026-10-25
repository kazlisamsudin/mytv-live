import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyTvLiveApp());
}

class MyTvLiveApp extends StatelessWidget {
  const MyTvLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MYTV Live',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101311),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB8F36B),
          secondary: Color(0xFFFF735A),
          surface: Color(0xFF191D1A),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const ChannelHomePage(),
    );
  }
}

enum _Portal { rtmklik, tonton }

class _Channel {
  const _Channel({
    required this.id,
    required this.name,
    required this.initials,
    required this.category,
    required this.portal,
    required this.color,
  });

  final String id;
  final String name;
  final String initials;
  final String category;
  final _Portal portal;
  final Color color;

  String get portalName => switch (portal) {
        _Portal.rtmklik => 'RTMKlik',
        _Portal.tonton => 'Tonton',
      };

  Uri get portalUri => Uri.parse(switch (portal) {
        _Portal.rtmklik => 'https://rtmklik.rtm.gov.my/',
        _Portal.tonton => 'https://www.tonton.com.my/',
      });
}

const _channels = <_Channel>[
  _Channel(
    id: 'tv1',
    name: 'TV1',
    initials: 'TV1',
    category: 'NATIONAL',
    portal: _Portal.rtmklik,
    color: Color(0xFFE85F42),
  ),
  _Channel(
    id: 'tv2',
    name: 'TV2',
    initials: 'TV2',
    category: 'ENTERTAINMENT',
    portal: _Portal.rtmklik,
    color: Color(0xFF55AFA0),
  ),
  _Channel(
    id: 'tvokey',
    name: 'TV Okey',
    initials: 'OKEY',
    category: 'LIFESTYLE',
    portal: _Portal.rtmklik,
    color: Color(0xFFE3AC4A),
  ),
  _Channel(
    id: 'berita-rtm',
    name: 'Berita RTM',
    initials: 'BERITA',
    category: 'NEWS',
    portal: _Portal.rtmklik,
    color: Color(0xFF6C9CE0),
  ),
  _Channel(
    id: 'sukan-rtm',
    name: 'Sukan RTM',
    initials: 'SUKAN',
    category: 'SPORTS',
    portal: _Portal.rtmklik,
    color: Color(0xFF8DB95E),
  ),
  _Channel(
    id: 'tv3',
    name: 'TV3',
    initials: 'TV3',
    category: 'ENTERTAINMENT',
    portal: _Portal.tonton,
    color: Color(0xFFEF735B),
  ),
  _Channel(
    id: '8tv',
    name: '8TV',
    initials: '8TV',
    category: 'ENTERTAINMENT',
    portal: _Portal.tonton,
    color: Color(0xFF9A7FC8),
  ),
  _Channel(
    id: 'tv9',
    name: 'TV9',
    initials: 'TV9',
    category: 'ENTERTAINMENT',
    portal: _Portal.tonton,
    color: Color(0xFFD78D4E),
  ),
  _Channel(
    id: 'didiktv',
    name: 'DidikTV KPM',
    initials: 'DIDIK',
    category: 'EDUCATION',
    portal: _Portal.tonton,
    color: Color(0xFF5FAFB5),
  ),
];

class ChannelHomePage extends StatefulWidget {
  const ChannelHomePage({super.key});

  @override
  State<ChannelHomePage> createState() => _ChannelHomePageState();
}

class _ChannelHomePageState extends State<ChannelHomePage> {
  static const _favoritesKey = 'favorite_channel_ids';

  final _searchController = TextEditingController();
  Set<String> _favorites = {};
  String _query = '';
  int _selectedTab = 0;
  bool _preferencesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favorites = preferences.getStringList(_favoritesKey)?.toSet() ?? {};
      _preferencesLoaded = true;
    });
  }

  Future<void> _toggleFavorite(_Channel channel) async {
    final updated = Set<String>.of(_favorites);
    if (!updated.add(channel.id)) updated.remove(channel.id);
    setState(() => _favorites = updated);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_favoritesKey, updated.toList());
  }

  List<_Channel> get _visibleChannels {
    final query = _query.trim().toLowerCase();
    return _channels.where((channel) {
      final matchesTab = _selectedTab == 0 || _favorites.contains(channel.id);
      final matchesQuery = query.isEmpty ||
          channel.name.toLowerCase().contains(query) ||
          channel.category.toLowerCase().contains(query) ||
          channel.portalName.toLowerCase().contains(query);
      return matchesTab && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final channels = _visibleChannels;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _preferencesLoaded
            ? CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildHeader(context),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildIntro()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    sliver: SliverToBoxAdapter(child: _buildSearch()),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeading(channels.length),
                    ),
                  ),
                  if (channels.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final count = width >= 900 ? 4 : width >= 580 ? 3 : 2;
                          return SliverGrid.builder(
                            itemCount: channels.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: count,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 184,
                            ),
                            itemBuilder: (context, index) => _ChannelCard(
                              channel: channels[index],
                              isFavorite:
                                  _favorites.contains(channels[index].id),
                              onFavorite: () =>
                                  _toggleFavorite(channels[index]),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _PortalPlayerPage(
                                    channel: channels[index],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFFB8F36B)),
              ),
      ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFB8F36B),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.play_arrow_rounded,
              color: Color(0xFF101311), size: 30),
        ),
        const SizedBox(width: 11),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MYTV',
              style: TextStyle(
                color: Color(0xFFF3F4EE),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xFFB8F36B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF343A35)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            children: [
              Icon(Icons.public, color: Color(0xFFB8F36B), size: 14),
              SizedBox(width: 6),
              Text(
                'MALAYSIA',
                style: TextStyle(
                  color: Color(0xFFC3C9C2),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFFB8F36B), size: 15),
            SizedBox(width: 7),
            Text(
              'OFFICIAL STREAMING PORTALS',
              style: TextStyle(
                color: Color(0xFFB8F36B),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.55,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        const Text(
          'Malaysia,\non your screen.',
          style: TextStyle(
            color: Color(0xFFF3F4EE),
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.03,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 11),
        const Text(
          'Choose a channel to open its official streaming portal.',
          style: TextStyle(color: Color(0xFF9CA49D), fontSize: 13, height: 1.45),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search channels or categories',
        hintStyle: const TextStyle(color: Color(0xFF818982), fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA49D)),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
        filled: true,
        fillColor: const Color(0xFF1A1E1B),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C322D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB8F36B), width: 1.2),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(int count) {
    return Row(
      children: [
        Text(
          _selectedTab == 0 ? 'CHANNELS' : 'YOUR FAVOURITES',
          style: const TextStyle(
            color: Color(0xFFF3F4EE),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.45,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          count.toString().padLeft(2, '0'),
          style: const TextStyle(
            color: Color(0xFF858D86),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        const Icon(Icons.open_in_new, color: Color(0xFF858D86), size: 13),
        const SizedBox(width: 5),
        const Text(
          'OFFICIAL SOURCES',
          style: TextStyle(
            color: Color(0xFF858D86),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isFavorites = _selectedTab == 1 && _query.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFavorites ? Icons.favorite_border : Icons.search_off_rounded,
              color: const Color(0xFF687168),
              size: 34,
            ),
            const SizedBox(height: 12),
            Text(
              isFavorites ? 'No favourites yet' : 'No channels found',
              style: const TextStyle(
                color: Color(0xFFE7EAE3),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isFavorites
                  ? 'Tap the heart on a channel to save it here.'
                  : 'Try another channel name or category.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9CA49D), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return NavigationBar(
      height: 68,
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) => setState(() => _selectedTab = index),
      backgroundColor: const Color(0xFF171B18),
      indicatorColor: const Color(0xFF303A2C),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.live_tv_outlined),
          selectedIcon: Icon(Icons.live_tv),
          label: 'Channels',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border),
          selectedIcon: Icon(Icons.favorite),
          label: 'Favourites',
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.channel,
    required this.isFavorite,
    required this.onFavorite,
    required this.onTap,
  });

  final _Channel channel;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF191D1A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: channel.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      channel.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9CA49D),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.75,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      tooltip: isFavorite
                          ? 'Remove ${channel.name} from favourites'
                          : 'Add ${channel.name} to favourites',
                      onPressed: onFavorite,
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFFF735A)
                            : const Color(0xFF8D958E),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                height: 58,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: channel.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: channel.color.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    channel.initials,
                    maxLines: 1,
                    style: TextStyle(
                      color: channel.color,
                      fontSize: channel.initials.length > 4 ? 14 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      channel.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF3F4EE),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFFB8F36B), size: 16),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                channel.portalName,
                style: const TextStyle(
                  color: Color(0xFF929A93),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalPlayerPage extends StatefulWidget {
  const _PortalPlayerPage({required this.channel});

  final _Channel channel;

  @override
  State<_PortalPlayerPage> createState() => _PortalPlayerPageState();
}

class _PortalPlayerPageState extends State<_PortalPlayerPage> {
  late final WebViewController _controller;
  int _progress = 0;
  String? _errorMessage;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _errorMessage = null;
                _progress = 0;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _errorMessage = error.description;
                _progress = 0;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              return NavigationDecision.navigate;
            }
            unawaited(_openExternal(uri));
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(widget.channel.portalUri);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(const []);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _openExternal([Uri? uri]) async {
    final target = uri ?? widget.channel.portalUri;
    try {
      final opened = await launchUrl(target, mode: LaunchMode.externalApplication);
      if (!opened && mounted) _showBrowserError();
    } catch (_) {
      if (mounted) _showBrowserError();
    }
  }

  void _showBrowserError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open an external browser.')),
    );
  }

  Future<void> _toggleFullscreen() async {
    final enter = !_isFullscreen;
    setState(() => _isFullscreen = enter);
    await SystemChrome.setPreferredOrientations(
      enter
          ? const [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]
          : const [],
    );
    await SystemChrome.setEnabledSystemUIMode(
      enter ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _errorMessage = null;
      _progress = 0;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.channel.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                widget.channel.portalName,
                style: const TextStyle(color: Color(0xFF9CA49D), fontSize: 11),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Open official portal in browser',
          onPressed: _openExternal,
          icon: const Icon(Icons.open_in_browser),
        ),
        IconButton(
          tooltip: 'Reload portal',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: _isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
          onPressed: _toggleFullscreen,
          icon: Icon(_isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
        ),
      ],
    );

    return Scaffold(
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF171B18),
              titleSpacing: 0,
              title: toolbar,
            ),
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_progress < 100 && _errorMessage == null)
              Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(
                  value: _progress == 0 ? null : _progress / 100,
                  minHeight: 2,
                  backgroundColor: const Color(0xFF242A25),
                  color: const Color(0xFFB8F36B),
                ),
              ),
            if (_isFullscreen)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton.filledTonal(
                      tooltip: 'Exit fullscreen',
                      onPressed: _toggleFullscreen,
                      icon: const Icon(Icons.fullscreen_exit),
                    ),
                  ),
                ),
              ),
            if (_errorMessage != null) _buildErrorState(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xFF101311),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Color(0xFFFF735A), size: 36),
                  const SizedBox(height: 15),
                  const Text(
                    'Portal could not be loaded',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF3F4EE),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF9CA49D),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openExternal,
                        icon: const Icon(Icons.open_in_browser, size: 18),
                        label: const Text('Open in browser'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}