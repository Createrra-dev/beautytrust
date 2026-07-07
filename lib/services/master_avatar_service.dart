import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterAvatarService extends ChangeNotifier {
	MasterAvatarService._();

	static final MasterAvatarService instance = MasterAvatarService._();

	static const _prefsKey = 'master_avatar_path';
	static const _avatarFileName = 'master_avatar.jpg';

	final ImagePicker _imagePicker = ImagePicker();

	String? _avatarPath;
	var _isLoading = false;

	String? get avatarPath => _avatarPath;

	bool get isLoading => _isLoading;

	Future<void> load() async {
		final preferences = await SharedPreferences.getInstance();
		final savedPath = preferences.getString(_prefsKey);

		if (savedPath != null && await File(savedPath).exists()) {
			_avatarPath = savedPath;
		} else {
			_avatarPath = null;
			await preferences.remove(_prefsKey);
		}

		notifyListeners();
	}

	Future<bool> pickFromCamera() {
		return _pickImage(ImageSource.camera);
	}

	Future<bool> pickFromGallery() {
		return _pickImage(ImageSource.gallery);
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

		_avatarPath = savedPath;

		final preferences = await SharedPreferences.getInstance();
		await preferences.setString(_prefsKey, savedPath);
		notifyListeners();
	}
}
