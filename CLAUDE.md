# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a single-page Amazon Connect agent chat interface built with vanilla JavaScript, HTML, and CSS. The application provides a custom UI for agents to handle customer chat contacts through Amazon Connect's Contact Control Panel (CCP).

## Architecture

### Single-File Application
- **Main file**: [ChatDemo.html](ChatDemo.html) - Contains all HTML, CSS, and JavaScript in one 48KB file
- **Monolithic architecture** - No build system, modules, or frameworks
- **Pure vanilla JavaScript** with ES6+ features

### Key Dependencies
- **Amazon Connect Streams API v2.18.3** (CDN): Core CCP integration
- **Bootstrap 5.3.0** (CDN): UI styling and layout
- **amazon-connect-chat-interface.js**: 1.1MB bundled chat library (pre-compiled, contains React)
- **ringtone.mp3**: Audio notification for incoming chats

### Three-Column Layout
1. **Left**: Chat participants, CCP container, system log
2. **Middle**: Active chat messages and input
3. **Right**: Agent info and participant details

## Development Commands

### Running the Application
```bash
# Option 1: Open directly in browser
open ChatDemo.html

# Option 2: Python HTTP server
python3 -m http.server 8000
# Visit: http://localhost:8000/ChatDemo.html

# Option 3: Node.js http-server
npx http-server -p 8000
```

### No Build Process
- No package.json, webpack, or compilation steps
- Direct file serving required
- Changes take effect on browser refresh

## Configuration

### Required Setup
1. **Update Amazon Connect instance URL** in ChatDemo.html line 300:
   ```javascript
   instanceURL: "https://your-instance.my.connect.aws/"
   ```

2. **Configure CORS** in Amazon Connect console to allow your domain

3. **Update ringtone path** if serving from different location (line 345)

## Global State Management

The application uses `window` object for global state:
- `window.contact` - Current active contact
- `window.controllers` - Map of contactId to chat controllers
- `window.chatMessages` - Per-contact message buffers
- `window.currentContactId` - Currently selected contact

## Key Functions

### Contact Management
- `AcceptContact()` - Accept incoming chat
- `RejectContact()` - Reject incoming chat
- `EndContact()` - End active chat
- `selectParticipant(contactId)` - Switch between multiple chats

### Message Handling
- `sendChatMessage()` - Send message to customer
- `addChatMessage()` - Display real-time messages
- `loadChatMessages(contactId)` - Load messages when switching contacts

### Agent Operations
- `SetAgentState(state)` - Change agent availability
- `TransferChat()` - Transfer chat to another agent/queue
- `Logout()` - Sign out agent

## Multi-Session Support

The application handles multiple concurrent chat sessions:
- Each contact maintains separate message history
- Visual indicators show active session (blue highlight)
- Incoming contacts pulse with yellow animation
- Controllers cached per contact for session switching

## Language and Localization

- **Primary UI language**: Chinese (Simplified)
- Key terms: 聊天参与者 (Chat Participants), 登录 (Login), 退出 (Logout)
- Consider i18n support for multi-language environments

## Technical Constraints

### Browser Requirements
- Modern browser with ES6+ support (arrow functions, async/await, template literals)
- No polyfills included

### Amazon Connect Integration
- Requires valid Amazon Connect instance with chat enabled
- Agent accounts must be configured in Connect
- Application domain must be whitelisted in Connect console

## File References

When working with this codebase:
- All application logic is in [ChatDemo.html](ChatDemo.html)
- The bundled library [amazon-connect-chat-interface.js](amazon-connect-chat-interface.js) is pre-compiled and should not be edited
- Audio notifications use [ringtone.mp3](ringtone.mp3)

## Development Considerations

- **No error handling**: Limited try-catch blocks in current implementation
- **Global state conflicts**: Consider namespacing for future refactoring
- **Hard-coded configuration**: Should be externalized for different environments
- **Inline styles**: Consider extracting to separate CSS file for maintainability
- **Single file complexity**: May benefit from modularization as features grow