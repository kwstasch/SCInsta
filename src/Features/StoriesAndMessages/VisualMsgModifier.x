#import "../../Utils.h"

%hook IGDirectVisualMessage

- (NSInteger)viewMode {
    NSInteger mode = %orig;
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"] && mode == 0) {
        mode = 1;
    }
    return mode;
}

// --- FIX: Επίσης hook στο openedCount / hasBeenOpened ---
// Αν το μήνυμα ΔΕΝ έχει πραγματικά ανοιχτεί ακόμα, αφήστε το orig
// Αυτό εμποδίζει το cell να ξαναδείχνει "Προβολή Φωτογραφίας" μετά το άνοιγμα
- (NSInteger)openedCount {
    NSInteger count = %orig;
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"] && count > 0) {
        // Έχει ανοιχτεί — επέστρεψε κανονικά ώστε το UI να ενημερωθεί
        return count;
    }
    return count;
}

// Αν υπάρχει visualMessageState ή παρόμοιο:
- (NSInteger)visualMessageState {
    // 0 = unseen, 1 = opened, 2 = expired
    NSInteger state = %orig;
    if ([SCIUtils getBoolPref:@"disable_view_once_limitations"] && state == 0) {
        // Μην αλλάξουμε το state — αφήστε το Instagram να το διαχειριστεί κανονικά
    }
    return state;
}

%end
