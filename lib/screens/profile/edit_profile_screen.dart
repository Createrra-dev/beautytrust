import 'package:flutter/material.dart';

import '../../models/master_profile.dart';
import '../../services/api/app_api_repository.dart';
import '../../services/api/beauty_trust_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth/app_text_field.dart';
import '../../widgets/auth/auth_buttons.dart';

class EditProfileScreen extends StatefulWidget {
	const EditProfileScreen({
		super.key,
		required this.profile,
	});

	static const routeName = '/edit-profile';

	final MasterProfile profile;

	@override
	State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
	final _api = AppApiRepository();
	late final TextEditingController _nameController;
	late final TextEditingController _emailController;
	late final TextEditingController _badgeController;

	String? _errorText;
	var _isSaving = false;

	@override
	void initState() {
		super.initState();
		_nameController = TextEditingController(text: widget.profile.firstName);
		_emailController = TextEditingController(text: widget.profile.email ?? '');
		_badgeController = TextEditingController(text: widget.profile.badgeLabel);
	}

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_badgeController.dispose();
		super.dispose();
	}

	Future<void> _save() async {
		final name = _nameController.text.trim();
		final email = _emailController.text.trim();
		final badge = _badgeController.text.trim();

		if (name.length < 2) {
			setState(() => _errorText = 'Введите имя');
			return;
		}
		if (badge.isEmpty) {
			setState(() => _errorText = 'Введите значок мастера');
			return;
		}

		setState(() {
			_errorText = null;
			_isSaving = true;
		});

		try {
			final updated = await _api.updateProfile(
				firstName: name,
				email: email,
				badgeLabel: badge,
			);
			if (!mounted) {
				return;
			}
			Navigator.of(context).pop(updated);
		} on ApiException catch (error) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = error.message;
				_isSaving = false;
			});
		} catch (_) {
			if (!mounted) {
				return;
			}
			setState(() {
				_errorText = 'Не удалось сохранить профиль';
				_isSaving = false;
			});
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: AppColors.background,
			appBar: AppBar(
				backgroundColor: AppColors.background,
				foregroundColor: AppColors.textPrimary,
				elevation: 0,
				title: const Text('Редактирование'),
			),
			body: SafeArea(
				child: ListView(
					padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
					children: [
						AppTextField(
							label: 'Имя',
							controller: _nameController,
							hintText: 'Анна',
						),
						const SizedBox(height: 14),
						AppTextField(
							label: 'Email',
							controller: _emailController,
							hintText: 'anna@example.com',
							keyboardType: TextInputType.emailAddress,
						),
						const SizedBox(height: 14),
						AppTextField(
							label: 'Значок',
							controller: _badgeController,
							hintText: 'Премиум мастер',
						),
						if (_errorText != null) ...[
							const SizedBox(height: 16),
							Text(
								_errorText!,
								style: const TextStyle(color: AppColors.error, fontSize: 14),
							),
						],
						const SizedBox(height: 24),
						PrimaryAuthButton(
							label: _isSaving ? 'Сохранение…' : 'Сохранить',
							onPressed: _isSaving ? null : _save,
						),
					],
				),
			),
		);
	}
}
