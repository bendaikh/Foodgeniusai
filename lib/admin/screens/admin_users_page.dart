import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AdminService _adminService = AdminService();
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allUsers = snapshot.data ?? [];
        
        // Filter users based on search and selected filter
        final filteredUsers = allUsers.where((user) {
          // Search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesName = (user.name ?? '').toLowerCase().contains(query);
            final matchesEmail = user.email.toLowerCase().contains(query);
            if (!matchesName && !matchesEmail) return false;
          }
          
          // Plan filter
          if (_selectedFilter != 'All') {
            if (_selectedFilter == 'Free' && user.subscriptionTier != 'free') return false;
            if (_selectedFilter == 'Pro' && user.subscriptionTier != 'pro') return false;
            if (_selectedFilter == 'Elite' && user.subscriptionTier != 'elite') return false;
          }
          
          return true;
        }).toList();

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(allUsers.length),
                const SizedBox(height: 32),
                _buildFilters(),
                const SizedBox(height: 24),
                filteredUsers.isEmpty
                    ? _buildEmptyState()
                    : _buildUsersTable(filteredUsers),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalUsers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Management',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and monitor all registered users ($totalUsers total)',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add User'),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: Icon(Icons.search, color: AppTheme.greyText),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        ...['All', 'Free', 'Pro', 'Elite'].map((filter) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: FilterChip(
                label: Text(filter),
                selected: _selectedFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                selectedColor: AppTheme.primaryGreen,
                backgroundColor: AppTheme.cardBackground,
                labelStyle: TextStyle(
                  color: _selectedFilter == filter
                      ? Colors.white
                      : AppTheme.greyText,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildUsersTable(List<UserModel> users) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ...users.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('User', style: _headerStyle)),
          Expanded(flex: 2, child: Text('Email', style: _headerStyle)),
          Expanded(child: Text('Plan', style: _headerStyle)),
          Expanded(child: Text('Joined', style: _headerStyle)),
          Expanded(child: Text('Recipes', style: _headerStyle)),
          Expanded(child: Text('Status', style: _headerStyle)),
          SizedBox(width: 120, child: Text('Actions', style: _headerStyle)),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.greyText,
    letterSpacing: 1.2,
  );

  Widget _buildUserRow(UserModel user) {
    final planName = _getPlanName(user.subscriptionTier);
    final formattedDate = user.createdAt != null
        ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
        : 'N/A';
    final initials = (user.name ?? user.email)
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0] : '')
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name ?? user.email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              style: const TextStyle(color: AppTheme.greyText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPlanColor(user.subscriptionTier).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                planName,
                style: TextStyle(
                  color: _getPlanColor(user.subscriptionTier),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: Text(
              formattedDate,
              style: const TextStyle(color: AppTheme.greyText),
            ),
          ),
          Expanded(
            child: Text(
              user.totalRecipesGenerated.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.subscriptionStatus == 'active'
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.subscriptionStatus,
                style: TextStyle(
                  color: user.subscriptionStatus == 'active'
                      ? Colors.green
                      : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showEditUserDialog(user),
                  icon: const Icon(Icons.edit, color: AppTheme.primaryGreen),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () => _showUserDetails(user),
                  icon: const Icon(Icons.visibility, color: AppTheme.greyText),
                  tooltip: 'View',
                ),
                IconButton(
                  onPressed: () => _confirmDeleteUser(user),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlanName(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return 'Free Tier';
      case 'pro':
        return 'Gourmet Pro';
      case 'elite':
        return 'Michelin Elite';
      default:
        return tier;
    }
  }

  Color _getPlanColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'elite':
        return Colors.amber;
      case 'pro':
        return Colors.blue;
      case 'free':
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 24),
            const Text(
              'No users found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or filters'
                  : 'Get started by adding your first user',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddUserDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add First User'),
            ),
          ],
        ),
      ),
    );
  }

  // Add User Dialog
  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedTier = 'free';
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Add New User', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'John Doe',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'john@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Minimum 6 characters',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedTier,
                  decoration: const InputDecoration(
                    labelText: 'Subscription Tier',
                  ),
                  dropdownColor: AppTheme.cardBackground,
                  items: const [
                    DropdownMenuItem(value: 'free', child: Text('Free Tier')),
                    DropdownMenuItem(value: 'pro', child: Text('Gourmet Pro')),
                    DropdownMenuItem(value: 'elite', child: Text('Michelin Elite')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedTier = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty ||
                          emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (passwordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password must be at least 6 characters'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        await _adminService.createUser(
                          email: emailController.text.trim(),
                          password: passwordController.text,
                          name: nameController.text.trim(),
                          subscriptionTier: selectedTier,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ User created successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  // Edit User Dialog
  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    String selectedTier = user.subscriptionTier;
    String selectedStatus = user.subscriptionStatus;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text('Edit User', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTier,
                decoration: const InputDecoration(
                  labelText: 'Subscription Tier',
                ),
                dropdownColor: AppTheme.cardBackground,
                items: const [
                  DropdownMenuItem(value: 'free', child: Text('Free Tier')),
                  DropdownMenuItem(value: 'pro', child: Text('Gourmet Pro')),
                  DropdownMenuItem(value: 'elite', child: Text('Michelin Elite')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedTier = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                dropdownColor: AppTheme.cardBackground,
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _firestoreService.updateUser(
                    user.uid,
                    {
                      'name': nameController.text.trim(),
                      'subscriptionTier': selectedTier,
                      'subscriptionStatus': selectedStatus,
                    },
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // Show User Details
  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('User Details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', user.name ?? 'N/A'),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('User ID', user.uid),
            _buildDetailRow('Plan', _getPlanName(user.subscriptionTier)),
            _buildDetailRow('Status', user.subscriptionStatus),
            _buildDetailRow('Recipes', user.totalRecipesGenerated.toString()),
            _buildDetailRow('API Usage', user.apiUsageCount.toString()),
            _buildDetailRow('Role', user.role),
            if (user.createdAt != null)
              _buildDetailRow(
                'Joined',
                '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppTheme.greyText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Confirm Delete User
  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${user.name ?? user.email}? This action cannot be undone.',
          style: const TextStyle(color: AppTheme.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.deleteUser(user.uid);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ User deleted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
