import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class DynamicContentService {
  static final DynamicContentService _instance = DynamicContentService._internal();
  factory DynamicContentService() => _instance;
  DynamicContentService._internal();

  static const String _cacheVersionKey = 'dynamic_content_version';
  static const String _baseContentUrl = 'https://storage.googleapis.com/your-bucket-name/ngonnest/content';
  
  final Map<String, dynamic> _inMemoryCache = {};
  bool _isInitialized = false;
  
  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load cached content version
      final prefs = await SharedPreferences.getInstance();
      final cachedVersion = prefs.getString(_cacheVersionKey) ?? '1.0.0';
      
      // In a real app, you would fetch the latest version from your server
      // and compare with cachedVersion to check for updates
      _isInitialized = true;
    } catch (e) {
      log('Error initializing DynamicContentService: $e', name: 'DynamicContentService');
    }
  }
  
  // Get content with caching
  Future<dynamic> getContent(String contentKey, {String? defaultValue}) async {
    if (!_isInitialized) await initialize();
    
    // Check in-memory cache first
    if (_inMemoryCache.containsKey(contentKey)) {
      return _inMemoryCache[contentKey];
    }
    
    // Check local storage
    final localContent = await _getLocalContent(contentKey);
    if (localContent != null) {
      _inMemoryCache[contentKey] = localContent;
      return localContent;
    }
    
    // Fallback to default value
    return defaultValue;
  }
  
  // Preload and cache content
  Future<void> preloadContent(List<String> contentKeys) async {
    if (!_isInitialized) await initialize();
    
    for (final key in contentKeys) {
      await getContent(key);
    }
  }
  
  // Download and cache remote content
  Future<dynamic> fetchRemoteContent(String contentKey) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseContentUrl/$contentKey.json'),
        headers: {'Cache-Control': 'no-cache'},
      );
      
      if (response.statusCode == 200) {
        final dynamic content = jsonDecode(response.body);
        await _cacheContentLocally(contentKey, content);
        _inMemoryCache[contentKey] = content;
        return content;
      }
      return null;
    } catch (e) {
      log('Error fetching remote content: $e', name: 'DynamicContentService');
      return null;
    }
  }
  
  // Get local file path for cached content
  Future<String?> _getLocalContentPath(String contentKey) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return path.join(directory.path, 'dynamic_content', '$contentKey.json');
    } catch (e) {
      log('Error getting local content path: $e', name: 'DynamicContentService');
      return null;
    }
  }
  
  // Get locally cached content
  Future<dynamic> _getLocalContent(String contentKey) async {
    try {
      final filePath = await _getLocalContentPath(contentKey);
      if (filePath == null) return null;
      
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
      return null;
    } catch (e) {
      log('Error reading local content: $e', name: 'DynamicContentService');
      return null;
    }
  }
  
  // Cache content locally
  Future<void> _cacheContentLocally(String contentKey, dynamic content) async {
    try {
      final filePath = await _getLocalContentPath(contentKey);
      if (filePath == null) return;
      
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(content));
    } catch (e) {
      log('Error caching content locally: $e', name: 'DynamicContentService');
    }
  }
  
  // Clear all cached content
  Future<void> clearCache() async {
    try {
      _inMemoryCache.clear();
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'dynamic_content'));
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      log('Error clearing cache: $e', name: 'DynamicContentService');
    }
  }
  
  // Get image URL with caching support
  String getImageUrl(String imageName, {String? variant}) {
    final variantSuffix = variant != null ? '_$variant' : '';
    return '$_baseContentUrl/images/${imageName}${variantSuffix}.png';
  }
  
  // Get remote image with caching
  Future<File?> getCachedImage(String imageName, {String? variant}) async {
    final url = getImageUrl(imageName, variant: variant);
    final fileName = '${path.basenameWithoutExtension(imageName)}_${variant ?? 'default'}';
    final filePath = await _getLocalContentPath('images/$fileName');
    
    if (filePath == null) return null;
    
    final file = File(filePath);
    
    // Return cached file if it exists
    if (await file.exists()) {
      return file;
    }
    
    // Download and cache the image
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      log('Error downloading image: $e', name: 'DynamicContentService');
    }
    
    return null;
  }
}
