//
//  CaptionStatusData.swift
//  WebScanner
//
//

import Foundation

public struct CaptionCategory: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let iconName: String
    public let captions: [String]
    
    public init(id: String, title: String, iconName: String, captions: [String]) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.captions = captions
    }
}

public struct CaptionStatusData {
    public static let categories: [CaptionCategory] = [
        CaptionCategory(
            id: "happiness",
            title: "Happiness",
            iconName: "ic_Happiness",
            captions: [
                "Happiness is free, but my shopping habits disagree.",
                "Smiling because my problems haven't checked my location yet.",
                "Life is better when snacks are involved.",
                "I'm happy today, and honestly, that's suspicious.",
                "My happiness depends on food and good Wi-Fi.",
                "Smile now, worry about everything tomorrow.",
                "Happiness is finding money in your old jeans.",
                "I'm not lucky, I just have low expectations.",
                "A little happiness and a lot of coffee.",
                "My mood improves whenever someone says, \"Food is ready.\"",
                "Smiling because crying requires too much energy.",
                "Good vibes only, unless the internet stops working.",
                "My happiness battery is charged by weekends.",
                "Life feels better after a good nap.",
                "I'm collecting memories, not responsibilities.",
                "Happiness is cancelling plans without feeling guilty.",
                "I smile because my camera is watching.",
                "My favorite exercise is laughing at my own jokes.",
                "Today feels good, and I refuse to investigate why.",
                "Be happy; it confuses people who expect drama."
            ]
        ),
        CaptionCategory(
            id: "cool",
            title: "Cool",
            iconName: "ic_Cool",
            captions: [
                "I'm not ignoring you; I'm enjoying my peace.",
                "Too cool to panic, too broke to relax.",
                "My attitude comes with no instruction manual.",
                "I don't chase people; I chase good food.",
                "Born to stand out, forced to wake up early.",
                "My style is expensive, but my budget disagrees.",
                "I keep it cool because drama is exhausting.",
                "Confidence level: sending a message without checking spelling.",
                "I'm not everyone's type, and that's a discount.",
                "Less talking, more minding my own business.",
                "My silence is better than my explanation.",
                "Cool enough to forget why I entered the room.",
                "I'm the main character in my own confusion.",
                "I don't compete; I just exist dramatically.",
                "Looking calm while my brain runs 47 tabs.",
                "My vibe is premium, my bank account is basic.",
                "I have standards, but sometimes I have snacks.",
                "Stay classy, even when your phone falls on your face.",
                "I'm not lazy; I'm on energy-saving mode.",
                "Be yourself; everyone else is already taken."
            ]
        ),
        CaptionCategory(
            id: "funny",
            title: "Funny",
            iconName: "ic_Funny",
            captions: [
                "My bank account and I are avoiding unnecessary expenses.",
                "I followed my dreams, but they were sleeping.",
                "I'm not lazy; I'm charging my human battery.",
                "My bed and I have a serious relationship.",
                "I need six months of vacation twice a year.",
                "I started a healthy diet and immediately missed my old life.",
                "My brain has too many tabs open and none are responding.",
                "I woke up motivated, then went back to sleep.",
                "Exercise? I thought you said extra fries.",
                "I'm on a seafood diet: I see food and eat it.",
                "My wallet is like an onion; opening it makes me cry.",
                "I don't snore; I dream I'm a motorcycle.",
                "I need a new password for my motivation.",
                "My life is a comedy, but nobody gave me the script.",
                "I put my phone down and immediately forgot why.",
                "I'm great at multitasking: worrying about everything at once.",
                "My favorite childhood memory is not paying bills.",
                "I clean my room by moving everything to a different chair.",
                "I have a degree in overthinking.",
                "My alarm clock and I are no longer friends."
            ]
        ),
        CaptionCategory(
            id: "inspiring",
            title: "Inspiring",
            iconName: "ic_Inspiring",
            captions: [
                "Believe in yourself; everyone else is busy judging.",
                "Chase your dreams, not people who leave you on read.",
                "Every small step counts, especially when you're tired.",
                "Success starts when excuses end.",
                "Dream big, nap well, repeat.",
                "Be stronger than your strongest excuse.",
                "You can do anything, except please everyone.",
                "Progress is progress, even if it's just getting out of bed.",
                "Don't stop until you're proud, or at least until lunch.",
                "Your future needs you, not your excuses.",
                "Stay focused; your competition is probably sleeping.",
                "Great things take time, and instant noodles take three minutes.",
                "Never give up on yourself, even on Mondays.",
                "Make today count, because tomorrow has its own problems.",
                "Your only limit is how many times you hit snooze.",
                "Work hard in silence; let your success make the noise.",
                "Start now, because someday is not on the calendar.",
                "Be the reason someone believes in good people.",
                "Turn your struggles into stories worth telling.",
                "Keep going; even your phone needs charging sometimes."
            ]
        ),
        CaptionCategory(
            id: "life",
            title: "Life",
            iconName: "ic_Life",
            captions: [
                "Life is short, so order the extra fries.",
                "Adulthood is just Googling everything your parents knew.",
                "Life keeps testing me, and I forgot to study.",
                "Growing up means getting excited about new kitchen appliances.",
                "My life needs a pause button and a skip-intro option.",
                "Life is beautiful, especially when rent is already paid.",
                "I'm just trying to make memories and avoid responsibilities.",
                "Life is a journey, but I keep missing the directions.",
                "Some days I'm the hero; other days I'm looking for my charger.",
                "Life gets easier when you stop explaining yourself.",
                "I planned my life, but life left me on read.",
                "The older I get, the more I love staying home.",
                "Life is too short to argue with people who enjoy arguing.",
                "My five-year plan changes every five business days.",
                "Sometimes the best life decision is ordering pizza.",
                "Life taught me patience by making everything load slowly.",
                "I need a life update, preferably with fewer problems.",
                "Life is like a camera; sometimes you just need better lighting.",
                "I'm not lost; I'm exploring unexpected opportunities.",
                "Take life seriously, but not your embarrassing photos."
            ]
        ),
        CaptionCategory(
            id: "love",
            title: "Love",
            iconName: "ic_Love",
            captions: [
                "You're my favorite notification.",
                "I love you more than my weekend sleep.",
                "You're the reason I smile at my phone in public.",
                "Love means sharing your fries without counting them.",
                "My heart says romance; my brain says don't be silly.",
                "I fell for you, and now I need emotional insurance.",
                "You're my favorite person to annoy forever.",
                "I love you even when you steal my blanket.",
                "You're my happy place and my biggest distraction.",
                "My love language is food delivery.",
                "I knew you were special when I shared my dessert.",
                "You're cute, but have you brought me snacks?",
                "I love you more than Wi-Fi, almost.",
                "Our love story deserves a comedy award.",
                "You're the only person I willingly share my secrets with.",
                "I don't need butterflies; I need consistent communication.",
                "Love is saying \"nothing\" when something is definitely wrong.",
                "You're my favorite reason to check my phone.",
                "I love you even when your playlist is terrible.",
                "Forever sounds good, especially if you bring pizza."
            ]
        ),
        CaptionCategory(
            id: "party",
            title: "Party",
            iconName: "ic_Party",
            captions: [
                "I came for the music and stayed for the snacks.",
                "My dance moves need a warning label.",
                "Party now, remember the details later.",
                "My social battery is low, but the DJ is playing my song.",
                "I don't need a dance floor; I need confidence.",
                "Tonight's plan: look good and forget the password to tomorrow.",
                "My feet are dancing, but my brain wants to go home.",
                "Life's a party, and I'm looking for the food table.",
                "I dance like nobody's watching, because hopefully nobody is.",
                "One more song, said every tired person ever.",
                "My party outfit deserves more attention than my life choices.",
                "Good music, great friends, questionable dance moves.",
                "I'm here to make memories and lose my voice.",
                "If you need me, I'll be near the snacks.",
                "Dancing is my cardio, especially after eating.",
                "I don't have rhythm; I have enthusiasm.",
                "The party starts when the food arrives.",
                "My weekend personality has entered the building.",
                "I came, I saw, I took 200 pictures.",
                "Leave the worries at home and bring the dessert."
            ]
        ),
        CaptionCategory(
            id: "selfie",
            title: "Selfie",
            iconName: "ic_Selfie",
            captions: [
                "This selfie took 50 tries and one emotional breakdown.",
                "No filter, just excellent lighting and good luck.",
                "My camera roll is 90% selfies and 10% accidental screenshots.",
                "I woke up like this, after several adjustments.",
                "Looking innocent because the camera doesn't know my secrets.",
                "Taking selfies until my phone asks me to stop.",
                "My best angle deserves its own appreciation post.",
                "Confidence is posting the selfie you almost deleted.",
                "This face comes with unlimited expressions.",
                "I don't need a photographer; I need a patient friend.",
                "Smiling because the other 49 pictures were terrible.",
                "My phone storage is suffering for this beauty.",
                "Just me, my camera, and unrealistic expectations.",
                "Selfie level: checking the background 17 times.",
                "Too glam to give a damn, too tired to pose again.",
                "My front camera knows all my secrets.",
                "I call this look \"I have no idea what I'm doing.\"",
                "This picture is sponsored by good lighting.",
                "Looking like a million dollars on a ten-dollar budget.",
                "If confidence had a picture, it would be this one."
            ]
        ),
        CaptionCategory(
            id: "relationship",
            title: "Relationship",
            iconName: "ic_Relationship",
            captions: [
                "Our relationship is 50% love and 50% deciding what to eat.",
                "We argue like professionals and make up like hungry people.",
                "A perfect relationship includes stealing each other's food.",
                "You're always right, according to our relationship policy.",
                "Love is sharing passwords but hiding the last piece of cake.",
                "We are proof that opposites can annoy each other perfectly.",
                "Relationship status: stealing hoodies and denying it.",
                "We don't need a therapist; we need better communication and snacks.",
                "Our love language is sending memes at midnight.",
                "Together forever, or until you eat my leftovers.",
                "We finish each other's sentences and each other's food.",
                "I love you, even when you say \"I'm five minutes away.\"",
                "We have chemistry, comedy, and terrible decision-making.",
                "Our dates are 10% romance and 90% food.",
                "The secret to love is pretending to enjoy their favorite movie.",
                "We survived another argument about where to eat.",
                "Love means listening to the same story for the tenth time.",
                "You're my favorite notification and my biggest distraction.",
                "We may be weird separately, but together we're a disaster.",
                "Forever is a long time, but you still owe me dinner."
            ]
        ),
        CaptionCategory(
            id: "friendship",
            title: "Friendship",
            iconName: "ic_Friendship",
            captions: [
                "Best friends are therapists who don't charge money.",
                "We don't need a reason to laugh, just eye contact.",
                "Real friends know your secrets and help you hide the evidence.",
                "Friendship is roasting each other with unconditional love.",
                "We became friends because nobody else understood our weirdness.",
                "My best friend knows too much to ever leave.",
                "Friends who eat together stay together.",
                "We are the reason our group chat needs a warning label.",
                "Best friends: turning bad ideas into unforgettable memories.",
                "Our friendship is built on memes and mutual blackmail.",
                "I would help you hide a body, but first, explain the situation.",
                "Friends don't let friends text their exes alone.",
                "We can communicate entire conversations with one look.",
                "Friendship means borrowing clothes and returning them eventually.",
                "You're my favorite person to do absolutely nothing with.",
                "We don't gossip; we conduct unofficial investigations.",
                "My best friend is my unpaid life coach.",
                "Friends make the good times better and the bad selfies worse.",
                "We are like a really small, badly managed gang.",
                "Our friendship is forever, or until you eat my fries."
            ]
        ),
        CaptionCategory(
            id: "birthday",
            title: "Birthday",
            iconName: "ic_Birthday",
            captions: [
                "Another year older, but still waiting for adulthood to make sense.",
                "I'm not old; I'm a limited edition.",
                "Birthdays are just annual reminders to eat more cake.",
                "My age is increasing, but my maturity is buffering.",
                "Officially older, still emotionally five.",
                "Cake calories don't count on your birthday.",
                "Growing older is mandatory; growing up is optional.",
                "I deserve presents for surviving another year.",
                "One year wiser, several years more tired.",
                "My birthday wish is a bank account with unlimited funds.",
                "Aging like fine wine, sleeping like a tired potato.",
                "Another trip around the sun, still looking for the remote.",
                "I'm at the age where candles cost more than the cake.",
                "Birthday mood: accepting gifts and rejecting responsibilities.",
                "Keep calm; it's my birthday month.",
                "Today I'm the main character, tomorrow I'm back to normal.",
                "Getting older is easy; remembering your age is the challenge.",
                "My birthday outfit is ready; my life plan isn't.",
                "More candles, more wishes, more reasons to eat cake.",
                "I'm celebrating my birthday because being this fabulous takes effort."
            ]
        ),
        CaptionCategory(
            id: "thanksgiving",
            title: "Thanksgiving",
            iconName: "ic_Thanksgiving",
            captions: [
                "Thankful for family, friends, and stretchy pants.",
                "Thanksgiving: when leftovers become the next week's meal plan.",
                "I'm grateful for food that doesn't ask personal questions.",
                "My gratitude list starts with dessert.",
                "Thankful for the people who tolerate my appetite.",
                "Today we give thanks and tomorrow we count leftovers.",
                "Family, food, and pretending I helped cook.",
                "Thanksgiving calories are officially on vacation.",
                "I came with gratitude and left with three food containers.",
                "My favorite tradition is eating before everyone arrives.",
                "Thankful for full plates and empty responsibilities.",
                "The turkey isn't the only thing getting roasted today.",
                "Gratitude looks good on me, but gravy looks better.",
                "I'm thankful my family doesn't charge me for every embarrassing story.",
                "Eat, laugh, repeat; that's my gratitude practice.",
                "Thanksgiving is proof that food brings people together.",
                "I give thanks for the person who invented mashed potatoes.",
                "Family gatherings: where love is served with unsolicited advice.",
                "I'm grateful for this meal and the nap afterward.",
                "May your blessings be many and your dishes be someone else's job."
            ]
        ),
        CaptionCategory(
            id: "travel",
            title: "Travel",
            iconName: "ic_Travel",
            captions: [
                "I need a vacation from planning my vacation.",
                "Catch flights, not feelings, unless they come with hotel points.",
                "My passport has more ambition than my Monday mornings.",
                "Traveling is expensive, but staying home makes me dream.",
                "I followed the map and somehow found a food market.",
                "My suitcase is packed; my responsibilities are not invited.",
                "Vacation mode: activated, email notifications: ignored.",
                "I travel to collect memories and fridge magnets.",
                "My favorite destination is anywhere with good food.",
                "I need more stamps in my passport and fewer bills at home.",
                "Getting lost is just sightseeing without a plan.",
                "My travel budget says local; my dreams say international.",
                "I haven't been everywhere, but it's on my bucket list.",
                "Airport outfit: comfortable enough to sleep anywhere.",
                "Travel far, eat well, take too many pictures.",
                "I came for the views and stayed for the street food.",
                "My out-of-office reply is my favorite sentence.",
                "The best souvenirs are memories and questionable purchases.",
                "I need a map, a charger, and someone who reads directions.",
                "Adventure is calling, but first, let me check hotel prices."
            ]
        ),
        CaptionCategory(
            id: "anniversary",
            title: "Anniversary",
            iconName: "ic_Anniversary",
            captions: [
                "Another year together and you still haven't learned to share snacks.",
                "We survived another year of my dramatic storytelling.",
                "Love is finding someone who tolerates your weird habits.",
                "Happy anniversary to my favorite person to annoy.",
                "Another year of romance, laughter, and asking what to eat.",
                "We make a great team, especially when ordering food.",
                "You're still my favorite person, even when you steal the blanket.",
                "Our love has aged better than the leftovers in our fridge.",
                "Together, we've mastered the art of doing nothing beautifully.",
                "Happy anniversary to the one who knows all my passwords.",
                "One more year of pretending we agree on everything.",
                "Our relationship deserves a trophy for surviving our moods.",
                "We grew together, laughed together, and shared dessert reluctantly.",
                "Still in love, still arguing about the thermostat.",
                "Every year with you is a new chapter in our comedy.",
                "You're my forever person and my favorite food thief.",
                "Cheers to another year of love and terrible jokes.",
                "Our anniversary is proof that patience really is romantic.",
                "I choose you every day, especially when you bring coffee.",
                "Forever with you sounds perfect, as long as we order dessert."
            ]
        ),
        CaptionCategory(
            id: "family",
            title: "Family",
            iconName: "ic_Family",
            captions: [
                "Family is where your embarrassing childhood stories never die.",
                "My family group chat deserves its own reality show.",
                "Home is where the food is free and the advice is unlimited.",
                "Family dinners: eating, laughing, and answering 100 questions.",
                "Nobody can embarrass me like my own family can.",
                "We may be crazy, but at least we're crazy together.",
                "Family is a little bit of love and a lot of noise.",
                "My relatives know my entire life story without reading my biography.",
                "Home is where you open the fridge five times hoping something new appears.",
                "Family gatherings are just friendly interrogations with snacks.",
                "I love my family, even when they use my full name.",
                "In my family, silence usually means someone is eating.",
                "Our family motto: nobody leaves hungry or without advice.",
                "Family is having people who annoy you and still save you a plate.",
                "My family can turn a five-minute visit into a three-hour meeting.",
                "We don't need entertainment; we have family stories.",
                "Family love is unconditional, but Wi-Fi passwords have conditions.",
                "My family is proof that weirdness runs in the genes.",
                "No matter how old I get, someone will ask if I've eaten.",
                "Family: the only team I can't quit, even when they steal my food."
            ]
        )
    ]
}
