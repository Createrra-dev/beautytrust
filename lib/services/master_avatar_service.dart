import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/app_api_repository.dart';
import 'api/beauty_trust_api.dart';
import 'auth_session.dart';

class MasterAvatarService extends ChangeNotifier {
	MasterAvatarService._();

	static final MasterAvatarService instance = MasterAvatarService._();

	static const _prefsKey = 'master_avatar_path';
	static const _avatarFileName = 'master_avatar.jpg';

	final ImagePicker _imagePicker = ImagePicker();
	final AppApiRepository _api = AppApiRepository();

	String? _localPath;
	String? _remoteUrl;
	var _isLoading = false;

	/// Local file path if present, otherwise null (use [remoteUrl]).
	String? get avatarPath => _localPath;

	String? get remoteUrl => _remoteUrl;

	bool get isLoading => _isLoading;

	Future<void> load({String? remoteUrl}) async {
		if (remoteUrl != null) {
			_remoteUrl = remoteUrl;
		}

		final preferences = await SharedPreferences.getInstance();
		final savedPath = preferences.getString(_prefsKey);

		if (savedPath != null && await File(savedPath).exists()) {
			_localPath = savedPath;
		} else {
			_localPath = null;
			await preferences.remove(_prefsKey);
		}

		notifyListeners();
	}

	void applyRemoteUrl(String? url) {
		_remoteUrl = url;
		notifyListeners();
	}

	Future<bool> pickFromCamera() {
		return _pickImage(ImageSource.camera);
	}

	Future<bool> pickFromGallery() {
		return _pickImage(ImageSource.gallery);
	}

	Future<bool> removeAvatar() async {
		_isLoading = true;
		notifyListeners();

		try {
			await AuthSession.load();
			if (AuthSession.isAuthenticated) {
				try {
					final profile = await _api.deleteAvatar();
					_remoteUrl = profile.avatarUrl;
				} on ApiException {
					// Fall through to local clear.
				}
			}

			await _clearLocal();
			return true;
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	Future<bool> _pickImage(ImageSource source) async {
		_isLoading = true;
		notifyListeners();

		try {
			final pickedImage = await _imagePicker.pickImage(
				source: source,
				maxWidth: 1024,
				maxHeight: 1024,
				imageQuality: 85,
			);

			if (pickedImage == null) {
				return false;
			}

			await _savePickedImage(pickedImage);

			await AuthSession.load();
			if (AuthSession.isAuthenticated) {
				try {
					final profile = await _api.uploadAvatar(_localPath!);
					_remoteUrl = profile.avatarUrl;
				} on ApiException {
					// Keep local avatar as fallback.
				}
			}

			return true;
		} finally {
			_isLoading = false;
			notifyListeners();
		}
	}

	Future<void> _savePickedImage(XFile pickedImage) async {
		final documentsDirectory = await getApplicationDocumentsDirectory();
		final savedPath = '${documentsDirectory.path}/$_avatarFileName';
		await File(pickedImage.path).copy(savedPath);

		_localPath = savedPath;

		final preferences = await SharedPreferences.getInstance();
		await preferences.setString(_prefsKey, savedPath);
		notifyListeners();
	}

	Future<void> _clearLocal() async {
		_localPath = null;
		final preferences = await SharedPreferences.getInstance();
		await preferences.remove(_prefsKey);

		final documentsDirectory = await getApplicationDocumentsDirectory();
		final file = File('${documentsDirectory.path}/$_avatarFileName');
		if (await file.exists()) {
			await file.delete();
		}
	}
}
