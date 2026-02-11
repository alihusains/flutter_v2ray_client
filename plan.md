Add Subscription URL Support & v2rayNG-style UI
Problem Statement
The flutter_v2ray_client example app currently has a basic UI with manual config entry. Need to add:
Subscription URL support (fetch & parse multiple server configs)
v2rayNG-style UI with server list, groups, and action menus
Current State
Example app at example/lib/main.dart has basic config text input
Plugin already supports parsing vmess, vless, trojan, shadowsocks, socks URLs
No subscription URL fetching or local storage for servers
Proposed Changes
1. Add Dependencies (example/pubspec.yaml)
http - for fetching subscription URLs
shared_preferences - for local storage of servers/subscriptions
2. Create Data Models (example/lib/models/)
server_config.dart - Server model with URL, remark, protocol, address, port, group
subscription.dart - Subscription model with URL, name, servers list
3. Create Services (example/lib/services/)
subscription_service.dart - Fetch URL, detect base64, parse multiple server URLs
storage_service.dart - Save/load servers and subscriptions using shared_preferences
4. Redesign UI (example/lib/)
main.dart - App entry with MaterialApp theming
pages/home_page.dart - Main screen with AppBar, tabs for groups, server list, FAB
pages/add_subscription_page.dart - Dialog/page to add subscription URL
widgets/server_list_item.dart - Server card with share/edit/delete buttons
widgets/add_menu.dart - "+" menu (import from clipboard, URL, QR, manual types)
widgets/overflow_menu.dart - "⋮" menu (delete, export, test delay, update subscription)
5. Key Features
Tab bar showing "All groups" + subscription names
Server list with protocol badge (TROJAN, VMESS, etc.)
Import from clipboard, subscription URL
Test server delay (tcping)
Connect/disconnect via FAB
Status bar at bottom showing connection state