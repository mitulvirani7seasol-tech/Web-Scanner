//
//  AccountManager.swift
//  WebScanner
//

import Foundation
import WebKit
import Combine

public enum WebAppPlatform: String, Codable, CaseIterable, Identifiable {
    case whatsApp = "WhatsApp"
    case telegram = "Telegram"
    case facebook = "Facebook"
    case instagram = "Instagram"
    case twitter = "Twitter"
    case google = "Google"
    case other = "Other"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .whatsApp: return "WT Scan"
        case .telegram: return "Telegram"
        case .facebook: return "Facebook"
        case .instagram: return "Instagram"
        case .twitter: return "Twitter"
        case .google: return "Google"
        case .other: return "Other"
        }
    }
    
    public var initialURL: URL {
        switch self {
        case .whatsApp: return URL(string: "https://web.whatsapp.com")!
        case .telegram: return URL(string: "https://web.telegram.org")!
        case .facebook: return URL(string: "https://m.facebook.com")!
        case .instagram: return URL(string: "https://www.instagram.com")!
        case .twitter: return URL(string: "https://x.com")!
        case .google: return URL(string: "https://accounts.google.com/ServiceLogin?continue=https%3A%2F%2Fmyaccount.google.com%2F")!
        case .other: return URL(string: "https://www.google.com")!
        }
    }
    
    public var iconAssetName: String {
        switch self {
        case .whatsApp: return "ic_wp"
        case .telegram: return "ic_telegram"
        case .facebook: return "ic_facebook"
        case .instagram: return "ic_instagram"
        case .twitter: return "ic_X"
        case .google: return "ic_Google"
        case .other: return "ic_Google"
        }
    }
    
    public var userAgent: String {
        switch self {
        case .whatsApp:
            // WhatsApp Web requires Desktop Safari/Chrome User Agent
            return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        default:
            return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        }
    }
    
    /// JavaScript snippet to detect active login state
    public var loginDetectJS: String {
        switch self {
        case .whatsApp:
            return """
            (function() {
                var isQR = document.querySelector('[data-ref]') != null || document.querySelector('canvas') != null;
                if (isQR) return JSON.stringify({loggedIn: false, name: ''});
                var chatList = document.querySelector('#pane-side') || document.querySelector('[data-testid="chat-list"]');
                if (chatList) {
                    return JSON.stringify({loggedIn: true, name: document.title || 'WhatsApp Account'});
                }
                return JSON.stringify({loggedIn: false, name: ''});
            })()
            """
        case .telegram:
            return """
            (function() {
                var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                
                // Strict auth screen detection only
                var hasPhoneInput = document.querySelector('input[type="tel"], input[name="phone-number"], #sign-in-phone-number') != null;
                var hasCodeInput = document.querySelector('input[name="phone-code"], input[autocomplete="one-time-code"]') != null;
                var hasQRCanvas = document.querySelector('#auth-pages canvas, .qr-container canvas, .auth-image canvas, .login_page canvas') != null;
                var hasAuthClass = document.querySelector('.auth-pages, #auth-pages, .qr-container, .auth-image, .qr-code, .login_page, .login-form') != null;
                var hasAuthText = bodyText.includes('log in to telegram')
                               || bodyText.includes('log in by phone')
                               || bodyText.includes('scan this code')
                               || bodyText.includes('quick log in')
                               || bodyText.includes('scan from mobile');
                
                var isAuthScreen = hasPhoneInput || hasCodeInput || hasQRCanvas || hasAuthClass || hasAuthText;
                
                if (isAuthScreen) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'auth_screen'});
                }
                
                // If body has meaningful content and no auth, check for any chat/sidebar indicators
                // Telegram Web K uses #app or .page-chats when logged in
                // Telegram Web A uses specific classes
                var loggedInSelectors = [
                    '.chatlist-chat',
                    '.ListItem.chat-item-clickable',
                    '#folders-tabs',
                    '.sidebar-header',
                    '.chat-list',
                    '.tabs-container',
                    'a.ListItem',
                    '.left-column-header',
                    '.menu-button',
                    '.btn-menu',
                    'div[data-peer-id]',
                    '.left-column',
                    '#left-column',
                    '.page-chats',
                    '.chats-container',
                    '#app .sidebar',
                    '.ChatsTabPanel',
                    '.ripple-container',
                    '.search-group'
                ];
                
                var matchedSelector = '';
                for (var i = 0; i < loggedInSelectors.length; i++) {
                    if (document.querySelector(loggedInSelectors[i]) != null) {
                        matchedSelector = loggedInSelectors[i];
                        break;
                    }
                }
                
                if (matchedSelector) {
                    return JSON.stringify({loggedIn: true, name: '', debug: 'matched:' + matchedSelector});
                }
                
                // Fallback: if body has substantial content and no auth screen, likely logged in
                var bodyLen = bodyText.length;
                var hasSearchBar = document.querySelector('input[type="search"], input[placeholder*="Search"], input[placeholder*="search"]') != null;
                if (bodyLen > 200 && hasSearchBar && !isAuthScreen) {
                    return JSON.stringify({loggedIn: true, name: '', debug: 'fallback_search_bar'});
                }
                
                return JSON.stringify({loggedIn: false, name: '', debug: 'no_match, bodyLen:' + bodyLen});
            })()
            """
        case .facebook:
            return """
            (function() {
                var url = window.location.href || '';
                var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                
                // Strict auth detection only
                var isAuthUrl = url.includes('/login') || url.includes('/checkpoint') || url.includes('/recover') || url.includes('/reg') || url.includes('r.php');
                var isAuthDom = document.querySelector('input[type="password"]') != null
                             || document.querySelector('input[name="pass"]') != null
                             || document.querySelector('input[name="email"]') != null
                             || document.querySelector('#loginform, #login_form, form[action*="login"]') != null
                             || document.querySelector('[data-testid="royal_login_button"]') != null
                             || document.querySelector('button[name="login"]') != null;
                var isAuthText = bodyText.includes('log in to facebook') 
                              || bodyText.includes('create new account')
                              || bodyText.includes('લૉગ ઇન');
                
                if (isAuthUrl || isAuthDom || isAuthText) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'auth:url=' + isAuthUrl + ',dom=' + isAuthDom + ',text=' + isAuthText});
                }
                
                // If we are on facebook.com domain and body has content => check for any logged-in indicator
                var isFBDomain = url.includes('facebook.com') || url.includes('fb.com');
                if (!isFBDomain) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'not_fb_domain:' + url.slice(0,60)});
                }
                
                function extractFacebookName() {
                    try {
                        // 1. Profile image alt attribute (e.g. "Rahul Patel's profile picture" or "Profile picture of Rahul Patel")
                        var imgs = document.querySelectorAll('img[alt]');
                        for (var i = 0; i < imgs.length; i++) {
                            var alt = imgs[i].getAttribute('alt') || '';
                            var lowerAlt = alt.toLowerCase();
                            if (lowerAlt.includes('profile') || lowerAlt.includes('picture of') || lowerAlt.includes('photo of')) {
                                var clean = alt.replace(/['’]s\\s+profile\\s+picture/gi, '')
                                               .replace(/profile\\s+picture\\s+of\\s*/gi, '')
                                               .replace(/profile\\s+photo\\s+of\\s*/gi, '')
                                               .replace(/photo\\s+of\\s*/gi, '')
                                               .replace(/profile\\s+picture/gi, '')
                                               .replace(/profile\\s+photo/gi, '')
                                               .trim();
                                if (clean.length >= 2 && clean.length <= 40 && 
                                    !clean.startsWith('-') &&
                                    !clean.toLowerCase().includes('facebook') && 
                                    !clean.toLowerCase().includes('user') && 
                                    !clean.toLowerCase().includes('login') && 
                                    !clean.toLowerCase().includes('menu') &&
                                    !clean.includes('લૉગ ઇન') &&
                                    !clean.includes('સાઇન અપ')) {
                                    return clean;
                                }
                            }
                        }
                        
                        // 2. Profile link text or aria-label (e.g. href="/me" or href="/profile.php" or data-sigil="profile-link")
                        var links = document.querySelectorAll('a[href*="/me"], a[href*="/profile.php"], [data-sigil*="profile"]');
                        for (var j = 0; j < links.length; j++) {
                            var el = links[j];
                            var text = (el.innerText || el.textContent || el.getAttribute('aria-label') || '').trim();
                            var lines = text.split('\\n').map(function(s){ return s.trim(); }).filter(function(s){ return s.length > 0; });
                            for (var k = 0; k < lines.length; k++) {
                                var line = lines[k];
                                if (line.length >= 2 && line.length <= 35 && 
                                    !line.startsWith('-') &&
                                    !line.toLowerCase().includes('profile') && 
                                    !line.toLowerCase().includes('facebook') && 
                                    !line.toLowerCase().includes('menu') && 
                                    !line.toLowerCase().includes('home') && 
                                    !line.toLowerCase().includes('watch') && 
                                    !line.toLowerCase().includes('feed') &&
                                    !line.toLowerCase().includes('log in') &&
                                    !line.includes('લૉગ ઇન') &&
                                    !line.includes('સાઇન અપ')) {
                                    return line;
                                }
                            }
                        }
                        
                        // 3. User name inside navigation / header elements / bookmarks
                        var candidates = document.querySelectorAll('div[data-pagelet="LeftRail"] a[role="link"] span, div[role="navigation"] a span, div[data-sigil*="bookmarks"] strong, header strong, [data-sigil*="profile"] strong');
                        for (var m = 0; m < candidates.length; m++) {
                            var cText = (candidates[m].innerText || candidates[m].textContent || '').trim();
                            if (cText.length >= 2 && cText.length <= 35 && 
                                !cText.startsWith('-') &&
                                !cText.toLowerCase().includes('facebook') && 
                                !cText.toLowerCase().includes('home') && 
                                !cText.toLowerCase().includes('watch') && 
                                !cText.toLowerCase().includes('friends') && 
                                !cText.toLowerCase().includes('menu') &&
                                !cText.toLowerCase().includes('log in') &&
                                !cText.includes('લૉગ ઇન') &&
                                !cText.includes('સાઇન અપ')) {
                                return cText;
                            }
                        }
                    } catch(e) {}
                    return '';
                }
                
                var fetchedName = extractFacebookName();
                var hasUserCookie = document.cookie.includes('c_user=');
                
                // PRIMARY: Authentic logged-in DOM selectors (no generic div[role="main"])
                var loggedInSelectors = [
                    'a[href*="/logout"]',
                    'a[href*="logout.php"]',
                    '[data-sigil="m-promo-jewel"]',
                    '#MComposer',
                    '[data-sigil="scroll-area newsfeed_stream"]',
                    'div[role="feed"]',
                    '[data-sigil="jsc-nav-item"]',
                    'a[data-sigil*="feed"]',
                    'div[data-testid="mbasic_home_feed"]',
                    '#bookmarks_jewel',
                    'a[href*="/profile.php"]',
                    'div[data-pagelet="LeftRail"]',
                    'div[data-pagelet="Stories"]',
                    'div[data-pagelet="FeedUnit"]',
                    '#ssrb_left_nav_start',
                    'div[aria-label="Stories"]',
                    'div[data-pagelet="ProfileTilesFeed_0"]',
                    'div[data-pagelet="GroupFeed"]',
                    '[data-testid="left_nav_item_Home"]'
                ];
                
                var matchedSelector = '';
                for (var i = 0; i < loggedInSelectors.length; i++) {
                    if (document.querySelector(loggedInSelectors[i]) != null) {
                        matchedSelector = loggedInSelectors[i];
                        break;
                    }
                }
                
                if (matchedSelector || hasUserCookie) {
                    return JSON.stringify({loggedIn: true, name: fetchedName, debug: 'matched:' + (matchedSelector || 'c_user_cookie') + ',name:' + fetchedName});
                }
                
                // SECONDARY URL-based fallback: after login FB goes to /home.php or /?sk=h_nor or similar
                var isLoggedInUrl = url.includes('/home.php')
                                 || url.includes('?sk=h_nor')
                                 || url.includes('?sk=h_chr')
                                 || url.includes('?sk=welcome');
                
                if (isLoggedInUrl && bodyText.length > 200) {
                    return JSON.stringify({loggedIn: true, name: fetchedName, debug: 'fallback_url:' + url.slice(0,60) + ',name:' + fetchedName});
                }
                
                return JSON.stringify({loggedIn: false, name: '', debug: 'no_match,bodyLen:' + bodyText.length + ',url:' + url.slice(0,60)});
            })()
            """
        case .instagram:
            return """
            (function() {
                var url = window.location.href || '';
                var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                
                // Strict auth detection only
                var isAuthUrl = url.includes('/accounts/login')
                             || url.includes('/login')
                             || url.includes('/challenge')
                             || url.includes('/two_factor')
                             || url.includes('/accounts/emailsignup');
                             
                var hasPasswordInput = document.querySelector('input[type="password"], input[name="password"]') != null;
                var hasLoginForm = document.querySelector('form#loginForm, #loginForm, form[action*="login"]') != null;
                var hasUsernameInput = document.querySelector('input[name="username"]') != null;
                var isAuthDom = hasPasswordInput || hasLoginForm || (hasUsernameInput && url.includes('login'));
                
                var isAuthText = bodyText.includes('log in to instagram')
                              || bodyText.includes("don't have an account")
                              || bodyText.includes('sign up to see photos');
                
                if (isAuthUrl || isAuthDom || isAuthText) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'auth:url=' + isAuthUrl + ',dom=' + isAuthDom + ',text=' + isAuthText});
                }
                
                // Must be on instagram.com domain
                if (!url.includes('instagram.com')) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'not_ig_domain:' + url.slice(0,60)});
                }
                
                // Check authenticated session cookie
                var hasSessionCookie = document.cookie.includes('sessionid=') || document.cookie.includes('ds_user_id=');
                
                // PRIMARY: Authentic logged-in DOM selectors (strictly NO generic div[role="main"] or section main)
                var loggedInSelectors = [
                    'svg[aria-label="Home"]',
                    'svg[aria-label="Direct"]',
                    'svg[aria-label="Messages"]',
                    'a[href*="/direct/inbox/"]',
                    'svg[aria-label="New post"]',
                    'svg[aria-label="Your profile"]',
                    'svg[aria-label="Profile"]',
                    'a[href^="/"][role="link"] img[alt*="profile picture"]',
                    'div[data-testid="user-avatar"]',
                    'a[href="/accounts/activity/"]',
                    'a[href*="/reels/"]'
                ];
                
                var matchedSelector = '';
                for (var i = 0; i < loggedInSelectors.length; i++) {
                    if (document.querySelector(loggedInSelectors[i]) != null) {
                        matchedSelector = loggedInSelectors[i];
                        break;
                    }
                }
                
                if (matchedSelector || hasSessionCookie) {
                    var profileImg = document.querySelector('img[alt*="profile picture"]');
                    var name = profileImg ? (profileImg.getAttribute('alt') || '').replace(/'s profile picture/gi, '').replace(/profile picture/gi, '').trim() : '';
                    if (!name || name.includes('Instagram') || name.includes('Log In') || name.startsWith('-') || name.includes('લૉગ ઇન')) name = '';
                    return JSON.stringify({loggedIn: true, name: name, debug: 'matched:' + (matchedSelector || 'session_cookie')});
                }
                
                return JSON.stringify({loggedIn: false, name: '', debug: 'no_match,bodyLen:' + bodyText.length + ',url:' + url.slice(0,60)});
            })()
            """
        case .twitter:
            return """
            (function() {
                var url = window.location.href || '';
                var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                
                // Strict auth detection
                var isAuthScreen = url.includes('/login')
                                || url.includes('/i/flow/login')
                                || url.includes('/i/flow/signup')
                                || document.querySelector('input[autocomplete="username"]') != null
                                || document.querySelector('input[name="text"]') != null
                                || bodyText.includes('sign in to x')
                                || bodyText.includes('sign in to twitter')
                                || bodyText.includes("don't have an account");
                if (isAuthScreen) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'auth_screen'});
                }
                
                // Broad logged-in selectors
                var loggedInSelectors = [
                    '[data-testid="AppTabBar_Home_Link"]',
                    '[data-testid="SideNav_AccountSwitcher_Button"]',
                    'nav[aria-label="Primary"]',
                    '[data-testid="primaryColumn"]',
                    '[data-testid="tweet"]',
                    '[data-testid="tweetButtonInline"]',
                    'a[href="/home"]',
                    '[aria-label="Timeline: Your Home Timeline"]',
                    'div[data-testid="UserAvatar-Container-self"]',
                    'header[role="banner"]'
                ];
                
                var matchedSelector = '';
                for (var i = 0; i < loggedInSelectors.length; i++) {
                    if (document.querySelector(loggedInSelectors[i]) != null) {
                        matchedSelector = loggedInSelectors[i];
                        break;
                    }
                }
                
                if (matchedSelector || url.includes('/home')) {
                    var switcher = document.querySelector('[data-testid="SideNav_AccountSwitcher_Button"]');
                    var name = switcher ? (switcher.innerText || '').split('\\n')[0].trim() : '';
                    if (!name || name.includes('X') || name.includes('Log in') || name.includes('Twitter')) name = '';
                    return JSON.stringify({loggedIn: true, name: name, debug: 'matched:' + (matchedSelector || 'url_home')});
                }
                
                var allClasses = [];
                var allEls = document.querySelectorAll('[class]');
                for (var j = 0; j < Math.min(allEls.length, 15); j++) {
                    allClasses.push((allEls[j].className || '').toString().split(' ')[0]);
                }
                return JSON.stringify({loggedIn: false, name: '', debug: 'no_match, bodyLen:' + bodyText.length + ', url:' + url.slice(0,60)});
            })()
            """
        case .google:
            return """
            (function() {
                try {
                    var url = window.location.href || '';
                    var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                    
                    // 1. Strict auth screen detection: check if active login input is present or in middle of sign-in flow
                    var hasEmail = document.querySelector('input[type="email"]') != null;
                    var hasPassword = document.querySelector('input[type="password"]') != null;
                    var hasEmailOrPass = hasEmail || hasPassword;
                    
                    var isAuthUrl = (url.includes('/signin') || 
                                     url.includes('/ServiceLogin') || 
                                     url.includes('/v3/signin') || 
                                     url.includes('/identifier') || 
                                     url.includes('/challenge')) && !url.includes('myaccount.google.com');
                                     
                    var isAuthText = bodyText.includes('sign in to your google account') || 
                                     bodyText.includes('sign in with your google account') || 
                                     bodyText.includes('sign in - google accounts');
                    
                    var isAuthScreen = hasEmailOrPass || isAuthUrl || (isAuthText && !url.includes('myaccount.google.com'));
                    
                    if (isAuthScreen) {
                        return JSON.stringify({loggedIn: false, name: '', debug: 'auth_screen:inputs=' + hasEmailOrPass + ',authUrl=' + isAuthUrl});
                    }
                    
                    // Must be on a Google domain
                    if (!url.includes('google.com')) {
                        return JSON.stringify({loggedIn: false, name: '', debug: 'not_google_domain:' + url.slice(0,60)});
                    }
                    
                    // Function to extract Google user email (e.g. mitulvirani.7seasol@gmail.com)
                    function extractGoogleEmail() {
                        try {
                            var emailRegex = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}/;
                            
                            // A. Look at data-email or data-identifier attributes
                            var dataEls = document.querySelectorAll('[data-email], [data-identifier]');
                            for (var d = 0; d < dataEls.length; d++) {
                                var val = dataEls[d].getAttribute('data-email') || dataEls[d].getAttribute('data-identifier') || '';
                                if (val.includes('@')) return val.trim();
                            }
                            
                            // B. Look at aria-label on profile/account elements
                            var ariaEls = document.querySelectorAll('a[aria-label], button[aria-label], div[aria-label]');
                            for (var i = 0; i < ariaEls.length; i++) {
                                var rawAria = ariaEls[i].getAttribute('aria-label') || '';
                                var m1 = rawAria.match(emailRegex);
                                if (m1 && m1[0]) return m1[0].trim();
                            }
                            
                            // C. Look at imgs alt / title
                            var imgs = document.querySelectorAll('img[alt], img[title]');
                            for (var j = 0; j < imgs.length; j++) {
                                var imgTxt = (imgs[j].getAttribute('alt') || '') + ' ' + (imgs[j].getAttribute('title') || '');
                                var m2 = imgTxt.match(emailRegex);
                                if (m2 && m2[0]) return m2[0].trim();
                            }
                            
                            // D. Look in header or profile card text
                            var headerEls = document.querySelectorAll('header, #gb, nav, [role="banner"], [role="navigation"]');
                            for (var k = 0; k < headerEls.length; k++) {
                                var hText = headerEls[k].innerText || headerEls[k].textContent || '';
                                var m3 = hText.match(emailRegex);
                                if (m3 && m3[0]) return m3[0].trim();
                            }
                            
                            // E. Look in body text
                            var bText = document.body ? (document.body.innerText || '') : '';
                            var m4 = bText.match(emailRegex);
                            if (m4 && m4[0]) return m4[0].trim();
                        } catch(e) {}
                        return '';
                    }
                    
                    var fetchedName = extractGoogleEmail();
                    
                    // 2. Primary check: myaccount.google.com is explicitly the authenticated user portal
                    if (url.includes('myaccount.google.com') && !isAuthScreen) {
                        return JSON.stringify({loggedIn: true, name: fetchedName, debug: 'myaccount_dashboard,name:' + fetchedName});
                    }
                    
                    // 3. Secondary check: Logged-in DOM selectors
                    var loggedInSelectors = [
                        'a[href*="accounts.google.com/SignOutOptions"]',
                        'a[href*="/SignOutOptions"]',
                        'a[href*="myaccount.google.com"]',
                        'div.gb_d',
                        'div.gb_b',
                        'a.gb_d',
                        '#gb div[aria-label]',
                        '#gb a[href*="myaccount"]',
                        'div[data-ogsr-up]',
                        'div[jsname="EBc8Rd"]'
                    ];
                    
                    var matchedSelector = '';
                    for (var m = 0; m < loggedInSelectors.length; m++) {
                        if (document.querySelector(loggedInSelectors[m]) != null) {
                            matchedSelector = loggedInSelectors[m];
                            break;
                        }
                    }
                    
                    if (matchedSelector) {
                        return JSON.stringify({loggedIn: true, name: fetchedName, debug: 'matched:' + matchedSelector + ',name:' + fetchedName});
                    }
                    
                    // 4. Tertiary check: search / services page with profile button
                    if (url.includes('google.com') && !url.includes('accounts.google.com') && bodyText.length > 200) {
                        var hasAccountBtn = document.querySelector('a[href*="myaccount"]') != null ||
                                            document.querySelector('a[href*="SignOutOptions"]') != null;
                        if (hasAccountBtn) {
                            return JSON.stringify({loggedIn: true, name: fetchedName, debug: 'fallback_account_btn,name:' + fetchedName});
                        }
                    }
                    
                    return JSON.stringify({loggedIn: false, name: '', debug: 'no_match,bodyLen:' + bodyText.length + ',url:' + url.slice(0,60)});
                } catch(err) {
                    return JSON.stringify({loggedIn: false, name: '', debug: 'catch_error:' + (err && err.message ? err.message : err)});
                }
            })()
            """
        default:
            return """
            (function() {
                return JSON.stringify({loggedIn: false, name: ''});
            })()
            """
        }
    }
}

public struct AppAccount: Codable, Identifiable, Equatable, Hashable {
    public let id: String
    public var platform: WebAppPlatform
    public var accountName: String
    public var createdAt: Date
    public var webDataStoreID: String
    public var cookiesKey: String
    public var isSessionActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, platform, accountName, createdAt, webDataStoreID, cookiesKey, isSessionActive
    }
    
    public init(platform: WebAppPlatform, accountName: String = "", isSessionActive: Bool = false) {
        self.id = UUID().uuidString
        self.platform = platform
        self.accountName = accountName.isEmpty ? "\(platform.rawValue) 1" : accountName
        self.createdAt = Date()
        self.webDataStoreID = UUID().uuidString
        self.cookiesKey = "cookies_\(self.id)"
        self.isSessionActive = isSessionActive
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.platform = try container.decode(WebAppPlatform.self, forKey: .platform)
        self.accountName = try container.decode(String.self, forKey: .accountName)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.webDataStoreID = try container.decode(String.self, forKey: .webDataStoreID)
        self.cookiesKey = try container.decode(String.self, forKey: .cookiesKey)
        
        if let active = try? container.decodeIfPresent(Bool.self, forKey: .isSessionActive) {
            self.isSessionActive = active
        } else {
            if platform == .whatsApp {
                self.isSessionActive = !accountName.starts(with: "WhatsApp - ") && accountName != "WhatsApp"
            } else {
                self.isSessionActive = true
            }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(platform, forKey: .platform)
        try container.encode(accountName, forKey: .accountName)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(webDataStoreID, forKey: .webDataStoreID)
        try container.encode(cookiesKey, forKey: .cookiesKey)
        try container.encode(isSessionActive, forKey: .isSessionActive)
    }
}

@MainActor
public final class AccountManager: ObservableObject {
    public static let shared = AccountManager()
    private let accountsKey = "all_saved_web_accounts"
    
    @Published public private(set) var accounts: [AppAccount] = []
    
    private init() {
        loadAccounts()
    }
    
    public func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              var list = try? JSONDecoder().decode([AppAccount].self, from: data) else {
            self.accounts = []
            return
        }
        
        // Clean up any phone number names back to "WhatsApp - 1", "WhatsApp - 2", etc.
        var wpCount = 0
        for i in 0..<list.count {
            if list[i].platform == .whatsApp {
                wpCount += 1
                let name = list[i].accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                if Self.isPhoneNumber(name) || name.isEmpty || name == "WhatsApp" {
                    list[i].accountName = "WhatsApp - \(wpCount)"
                }
            }
        }
        
        // Resolve duplicate fallback names (e.g. two accounts both named "Facebook - 1")
        for plat in WebAppPlatform.allCases {
            let prefix = "\(plat.displayName) - "
            let altPrefix = "\(plat.rawValue) - "
            let platIndices = list.indices.filter { list[$0].platform == plat }
            // Sort by createdAt ascending so older account keeps lower number and newer gets next
            let sortedIndices = platIndices.sorted { list[$0].createdAt < list[$1].createdAt }
            
            var usedNumbers = Set<Int>()
            for idx in sortedIndices {
                let name = list[idx].accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                let numberStr: String?
                if name.starts(with: prefix) {
                    numberStr = String(name.dropFirst(prefix.count))
                } else if name.starts(with: altPrefix) {
                    numberStr = String(name.dropFirst(altPrefix.count))
                } else {
                    numberStr = nil
                }
                
                if let numStr = numberStr, let num = Int(numStr) {
                    if usedNumbers.contains(num) {
                        var next = 1
                        while usedNumbers.contains(next) {
                            next += 1
                        }
                        list[idx].accountName = "\(plat.displayName) - \(next)"
                        usedNumbers.insert(next)
                    } else {
                        usedNumbers.insert(num)
                    }
                }
            }
        }
        
        // Clean up any bogus Google names like "settings", "Open Help Center", etc.
        for i in 0..<list.count {
            if list[i].platform == .google {
                let name = list[i].accountName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if name == "settings" || name.contains("help center") || name == "account" || name.isEmpty {
                    if let cred = CoreDataManager.shared.getLatestCredential(for: "Google"), cred.username.contains("@") {
                        list[i].accountName = cred.username
                    } else {
                        list[i].accountName = "Google - 1"
                    }
                }
            }
        }
        
        // Sort accounts descending by createdAt so latest is always at the top
        list.sort { $0.createdAt > $1.createdAt }
        self.accounts = list
    }
    
    public static func isPhoneNumber(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed.starts(with: "+") { return true }
        let digitsOnly = trimmed.replacingOccurrences(of: " ", with: "")
                                .replacingOccurrences(of: "-", with: "")
                                .replacingOccurrences(of: "(", with: "")
                                .replacingOccurrences(of: ")", with: "")
        return digitsOnly.count >= 7 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: digitsOnly))
    }
    
    public func whatsappIndex(for account: AppAccount) -> Int {
        let whatsappAccounts = accounts.filter { $0.platform == .whatsApp }
        if let idx = whatsappAccounts.firstIndex(where: { $0.id == account.id }) {
            return idx + 1
        }
        return max(1, whatsappAccounts.count + 1)
    }
    
    public func platformAccounts(for platform: WebAppPlatform) -> [AppAccount] {
        accounts.filter { $0.platform == platform }
    }
    
    /// Finds the next unused number for fallback naming (e.g. 1 for "Facebook - 1", 2 for "Facebook - 2")
    public func nextAvailableNumber(for platform: WebAppPlatform, excludingAccountId: String? = nil) -> Int {
        let list = accounts.filter { $0.platform == platform && $0.id != excludingAccountId }
        var usedNumbers = Set<Int>()
        let prefix1 = "\(platform.displayName) - "
        let prefix2 = "\(platform.rawValue) - "
        for acc in list {
            let name = acc.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.starts(with: prefix1), let num = Int(name.dropFirst(prefix1.count)) {
                usedNumbers.insert(num)
            } else if name.starts(with: prefix2), let num = Int(name.dropFirst(prefix2.count)) {
                usedNumbers.insert(num)
            }
        }
        var next = 1
        while usedNumbers.contains(next) {
            next += 1
        }
        return next
    }
    
    public func platformIndex(for platform: WebAppPlatform, accountId: String? = nil) -> Int {
        if let id = accountId, let existing = accounts.first(where: { $0.id == id }) {
            let prefix = "\(platform.displayName) - "
            let altPrefix = "\(platform.rawValue) - "
            let name = existing.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.starts(with: prefix), let num = Int(name.dropFirst(prefix.count)) {
                return num
            } else if name.starts(with: altPrefix), let num = Int(name.dropFirst(altPrefix.count)) {
                return num
            }
        }
        return nextAvailableNumber(for: platform, excludingAccountId: accountId)
    }
    
    public func defaultAccountName(for platform: WebAppPlatform, accountId: String? = nil) -> String {
        if let id = accountId, let existing = accounts.first(where: { $0.id == id }) {
            let prefix = "\(platform.displayName) - "
            if existing.accountName.starts(with: prefix) {
                return existing.accountName
            }
        }
        let next = nextAvailableNumber(for: platform, excludingAccountId: accountId)
        return "\(platform.displayName) - \(next)"
    }
    
    public func resetWhatsAppSession(for account: inout AppAccount) {
        if #available(iOS 17.0, *) {
            if let uuid = UUID(uuidString: account.webDataStoreID) {
                WKWebsiteDataStore.remove(forIdentifier: uuid) { _ in }
            }
        }
        UserDefaults.standard.removeObject(forKey: account.cookiesKey)
        account.webDataStoreID = UUID().uuidString
        let idx = whatsappIndex(for: account)
        account.accountName = "WhatsApp - \(idx)"
        account.isSessionActive = false
        update(account)
    }
    
    public func save(_ account: AppAccount) {
        var list = accounts
        var updatedAccount = account
        updatedAccount.createdAt = Date() // Mark most recent time
        
        if let idx = list.firstIndex(where: { $0.id == updatedAccount.id }) {
            list.remove(at: idx)
        } else {
            if updatedAccount.accountName.isEmpty {
                let next = nextAvailableNumber(for: updatedAccount.platform)
                updatedAccount.accountName = "\(updatedAccount.platform.displayName) - \(next)"
            }
        }
        // Insert at index 0 so the latest account is at the TOP!
        list.insert(updatedAccount, at: 0)
        persist(list)
    }
    
    public func touch(_ account: AppAccount) {
        var list = accounts
        if let idx = list.firstIndex(where: { $0.id == account.id }) {
            var acc = list.remove(at: idx)
            acc.createdAt = Date()
            list.insert(acc, at: 0)
            persist(list)
        }
    }
    
    public func saveAccountWithCredentials(platform: WebAppPlatform, accountName: String, username: String) {
        let name = !username.isEmpty ? username : (!accountName.isEmpty ? accountName : "\(platform.displayName) Account")
        if let idx = accounts.firstIndex(where: { $0.platform == platform && ($0.accountName == name || $0.accountName.contains(name)) }) {
            var existing = accounts.remove(at: idx)
            existing.createdAt = Date()
            existing.isSessionActive = true
            accounts.insert(existing, at: 0)
            persist(accounts)
        } else {
            let newAcc = AppAccount(platform: platform, accountName: name, isSessionActive: true)
            save(newAcc)
        }
    }
    
    public func update(_ account: AppAccount) {
        var list = accounts
        if let idx = list.firstIndex(where: { $0.id == account.id }) {
            list.remove(at: idx)
            var updated = account
            updated.createdAt = Date()
            list.insert(updated, at: 0)
            persist(list)
        }
    }
    
    public func delete(id: String) {
        if let account = accounts.first(where: { $0.id == id }) {
            UserDefaults.standard.removeObject(forKey: account.cookiesKey)
            if #available(iOS 17.0, *) {
                if let uuid = UUID(uuidString: account.webDataStoreID) {
                    WKWebsiteDataStore.remove(forIdentifier: uuid) { _ in }
                }
            }
        }
        let list = accounts.filter { $0.id != id }
        persist(list)
    }
    
    public func dataStore(for account: AppAccount) -> WKWebsiteDataStore {
        if #available(iOS 17.0, *) {
            let uuid = UUID(uuidString: account.webDataStoreID) ?? UUID()
            return WKWebsiteDataStore(forIdentifier: uuid)
        } else {
            return WKWebsiteDataStore.default()
        }
    }
    
    private func persist(_ list: [AppAccount]) {
        self.accounts = list
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }
}

public extension AppAccount {
    var timeAgoFormatted: String {
        let diff = Int(Date().timeIntervalSince(createdAt))
        if diff < 60 {
            return "Just Now".localized
        } else if diff < 3600 {
            let m = max(1, diff / 60)
            return "\(m) " + (m == 1 ? "Minute Ago".localized : "Minutes Ago".localized)
        } else if diff < 86400 {
            let h = diff / 3600
            return "\(h) " + (h == 1 ? "Hour Ago".localized : "Hours Ago".localized)
        } else {
            let d = diff / 86400
            return "\(d) " + (d == 1 ? "Day Ago".localized : "Days Ago".localized)
        }
    }
}
