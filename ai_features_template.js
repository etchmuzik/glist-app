// AI Features Template for Glist App
// Venue recommendations, wait time predictions, and marketing automation

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'glist-6e64f'
});

const db = admin.firestore();

// 1. VENUE RECOMMENDATIONS ENGINE
class VenueRecommender {
  static async getPersonalizedRecommendations(userId, context = {}) {
    const { location, groupSize, budget, mood, timeOfDay } = context;

    console.log(`🤖 Generating recommendations for user ${userId}`);

    try {
      // Get user's booking history and preferences
      const userHistory = await this.getUserHistory(userId);
      const userPreferences = await this.analyzeUserPreferences(userHistory);

      // Get real-time venue data
      const venues = await this.getActiveVenues();

      // Score venues based on multiple factors
      const recommendations = await Promise.all(
        venues.map(async (venue) => {
          const score = await this.calculateVenueScore(venue, userHistory, userPreferences, context);
          return { ...venue, score };
        })
      );

      // Sort by score and return top recommendations
      return recommendations
        .sort((a, b) => b.score - a.score)
        .slice(0, 10);

    } catch (error) {
      console.error('❌ Recommendation generation failed:', error);
      throw error;
    }
  }

  static async getUserHistory(userId) {
    const bookings = await db.collection('bookings')
      .where('userId', '==', userId)
      .where('status', '==', 'completed')
      .orderBy('createdAt', 'desc')
      .limit(50)
      .get();

    return bookings.docs.map(doc => doc.data());
  }

  static analyzeUserPreferences(bookings) {
    const preferences = {
      priceRanges: {},
      venueTypes: {},
      timePreferences: {},
      groupSizeAvg: 0
    };

    bookings.forEach(booking => {
      // Price analysis
      const price = booking.depositAmount || booking.amount;
      const priceTier = this.getPriceTier(price);
      preferences.priceRanges[priceTier] = (preferences.priceRanges[priceTier] || 0) + 1;

      // Venue type preferences
      const venueType = booking.venueType || 'unknown';
      preferences.venueTypes[venueType] = (preferences.venueTypes[venueType] || 0) + 1;

      // Time preferences
      const hour = booking.timeOfDay || 20; // Default to evening
      const timeSlot = this.getTimeSlot(hour);
      preferences.timePreferences[timeSlot] = (preferences.timePreferences[timeSlot] || 0) + 1;

      // Group size analysis
      preferences.groupSizeAvg = preferences.groupSizeAvg + (booking.guestCount || 1);
    });

    preferences.groupSizeAvg = Math.round(preferences.groupSizeAvg / bookings.length);

    return preferences;
  }

  static getPriceTier(price) {
    if (price < 500) return 'budget';
    if (price < 2000) return 'moderate';
    if (price < 5000) return 'premium';
    return 'luxury';
  }

  static getTimeSlot(hour) {
    if (hour < 16) return 'afternoon';
    if (hour < 22) return 'evening';
    return 'late_night';
  }

  static getActiveVenues() {
    return db.collection('venues')
      .where('isActive', '==', true)
      .get()
      .then(snapshot => snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
  }

  static async calculateVenueScore(venue, userHistory, preferences, context) {
    let score = 50; // Base score

    // Preference matching (40% weight)
    if (preferences.venueTypes[venue.type]) {
      score += (preferences.venueTypes[venue.type] / Object.values(preferences.venueTypes).reduce((a, b) => a + b, 0)) * 40;
    }

    // Price compatibility (20% weight)
    const venuePriceTier = this.getPriceTier(venue.minSpend || 1000);
    if (preferences.priceRanges[venuePriceTier]) {
      score += 20;
    }

    // Time preference (15% weight)
    const currentHour = context.timeOfDay || new Date().getHours();
    const venueTimePreference = preferences.timePreferences[this.getTimeSlot(currentHour)];
    if (venueTimePreference) {
      score += 15;
    }

    // Group size compatibility (15% weight)
    const groupSize = context.groupSize || 4;
    const venueCapacity = venue.capacity || 8;
    if (groupSize <= venueCapacity) {
      score += 15 * (groupSize / venueCapacity);
    }

    // Location proximity (10% weight)
    if (context.location && venue.latitude && venue.longitude) {
      const distance = this.calculateDistance(context.location, { lat: venue.latitude, lng: venue.longitude });
      if (distance < 5) { // Within 5km
        score += 10;
      } else if (distance < 20) {
        score += 5;
      }
    }

    return Math.min(100, score);
  }

  static calculateDistance(point1, point2) {
    // Haversine formula for distance calculation
    const R = 6371; // Earth's radius in km
    const dLat = (point2.lat - point1.lat) * Math.PI / 180;
    const dLon = (point2.lng - point1.lng) * Math.PI / 180;
    const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
              Math.cos(point1.lat * Math.PI / 180) * Math.cos(point2.lat * Math.PI / 180) *
              Math.sin(dLon/2) * Math.sin(dLon/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c;
  }
}

// 2. WAIT TIME PREDICTIONS
class WaitTimePredictor {
  static async predictWaitTime(venueId, requestedTime, groupSize = 4) {
    console.log(`⏱️ Predicting wait time for venue ${venueId}`);

    try {
      // Get historical booking data for this venue
      const historicalData = await this.getHistoricalData(venueId, requestedTime);

      // Get current live occupancy
      const liveOccupancy = await this.getLiveOccupancy(venueId);

      // Calculate predicted wait time using ML algorithm
      const prediction = this.calculateWaitTime(historicalData, liveOccupancy, requestedTime, groupSize);

      return {
        venueId,
        requestedTime,
        estimatedWaitMinutes: Math.round(prediction.waitTime),
        confidence: prediction.confidence,
        alternativeTimes: prediction.alternatives
      };

    } catch (error) {
      console.error('❌ Wait time prediction failed:', error);
      return { venueId, estimatedWaitMinutes: null, confidence: 0 };
    }
  }

  static async getHistoricalData(venueId, requestedTime) {
    const now = new Date();
    const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

    const bookings = await db.collection('bookings')
      .where('venueId', '==', venueId)
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(oneMonthAgo))
      .get();

    return bookings.docs.map(doc => doc.data());
  }

  static async getLiveOccupancy(venueId) {
    // This would integrate with real-time occupancy tracking
    // For now, return mock data
    return {
      currentOccupancy: Math.floor(Math.random() * 70) + 10, // 10-80%
      totalCapacity: 100,
      tablesAvailable: Math.floor(Math.random() * 15) + 5 // 5-20 tables
    };
  }

  static calculateWaitTime(historical, liveOccupancy, requestedTime, groupSize) {
    // Simple ML prediction algorithm
    let avgWaitTime = 30; // Base 30 minutes

    // Factor in historical booking patterns
    const bookingsAtTime = historical.filter(booking => {
      const bookingHour = booking.createdAt.toDate().getHours();
      return Math.abs(bookingHour - requestedTime.getHours()) <= 1;
    });

    // High booking volume = longer wait
    if (bookingsAtTime.length > 10) avgWaitTime += 30;
    else if (bookingsAtTime.length > 5) avgWaitTime += 15;

    // Current occupancy factors
    const occupancyRate = liveOccupancy.currentOccupancy / liveOccupancy.totalCapacity;
    if (occupancyRate > 0.8) avgWaitTime += 45;
    else if (occupancyRate > 0.6) avgWaitTime += 20;

    // Group size factors
    if (groupSize > 6) avgWaitTime += 20;
    else if (groupSize > 4) avgWaitTime += 10;

    // Weekend surge pricing
    const dayOfWeek = requestedTime.getDay();
    if (dayOfWeek === 5 || dayOfWeek === 6) { // Friday/Saturday
      avgWaitTime *= 1.5;
    }

    return {
      waitTime: Math.min(180, avgWaitTime), // Max 3 hours
      confidence: bookingsAtTime.length > 5 ? 0.8 : 0.6,
      alternatives: this.generateAlternatives(requestedTime, avgWaitTime)
    };
  }

  static generateAlternatives(requestedTime, predictedWait) {
    const alternatives = [];
    const startTime = new Date(requestedTime);

    // Suggest earlier/later time slots with better wait times
    for (let hours = -2; hours <= 2; hours++) {
      if (hours === 0) continue; // Skip original time

      const alternative = new Date(startTime.getTime() + hours * 60 * 60 * 1000);
      const betterWait = Math.max(0, predictedWait - Math.abs(hours) * 15);

      alternatives.push({
        time: alternative,
        estimatedWait: Math.round(betterWait),
        improvement: predictedWait - betterWait
      });
    }

    return alternatives.sort((a, b) => a.estimatedWait - b.estimatedWait);
  }
}

// 3. DYNAMIC PRICING OPTIMIZATION
class PricingOptimizer {
  static async getOptimizedPrice(venueId, tableId, requestedTime, groupSize = 4) {
    console.log(`💰 Optimizing price for venue ${venueId}, table ${tableId}`);

    try {
      const basePrice = await this.getBasePrice(venueId, tableId);
      const demandMultiplier = await this.calculateDemandMultiplier(venueId, requestedTime);
      const personalizationDiscount = await this.getPersonalizationDiscount();

      // Dynamic pricing calculation
      const optimizedPrice = basePrice * demandMultiplier * (1 - personalizationDiscount);

      return {
        originalPrice: basePrice,
        optimizedPrice: Math.round(optimizedPrice),
        savings: Math.round(basePrice - optimizedPrice),
        demandFactor: demandMultiplier,
        personalDiscount: personalizationDiscount
      };

    } catch (error) {
      console.error('❌ Price optimization failed:', error);
      return { originalPrice: 1000, optimizedPrice: 1000, savings: 0 };
    }
  }

  static async getBasePrice(venueId, tableId) {
    const venueDoc = await db.collection('venues').doc(venueId).get();
    if (!venueDoc.exists) throw new Error('Venue not found');

    const venue = venueDoc.data();
    const table = venue.tables.find(t => t.id === tableId);
    return table?.minimumSpend || 1000;
  }

  static async calculateDemandMultiplier(venueId, requestedTime) {
    // Factors for demand calculation
    let multiplier = 1.0;

    const bookings = await db.collection('bookings')
      .where('venueId', '==', venueId)
      .where('status', 'in', ['pending', 'confirmed'])
      .get();

    const currentBookings = bookings.docs.filter(doc => {
      const booking = doc.data();
      const bookingTime = booking.date?.toDate();
      if (!bookingTime) return false;

      const diff = Math.abs(bookingTime.getTime() - requestedTime.getTime());
      return diff < (2 * 60 * 60 * 1000); // Within 2 hours
    }).length;

    // High demand = higher prices
    if (currentBookings > 8) multiplier += 0.3; // 30% surge
    else if (currentBookings > 5) multiplier += 0.15; // 15% increase

    // Peak hours (Friday/Saturday 8pm-2am)
    const hour = requestedTime.getHours();
    const day = requestedTime.getDay();
    const isPeak = (day === 5 || day === 6) && (hour >= 20 || hour <= 2);
    if (isPeak) multiplier += 0.2;

    return Math.min(2.0, multiplier); // Max 2x surge
  }

  static async getPersonalizationDiscount() {
    // This would analyze user loyalty, booking frequency, etc.
    // For now, return random "personalization" discount
    const discounts = [0, 0.05, 0.1, 0.15]; // 0%, 5%, 10%, 15% off
    return discounts[Math.floor(Math.random() * discounts.length)];
  }
}

// 4. MARKETING AUTOMATION ENGINE
class MarketingAutomator {
  static async generatePersonalizedCampaign(userId) {
    console.log(`📢 Generating marketing campaign for user ${userId}`);

    try {
      const userData = await this.getUserProfile(userId);
      const userBehavior = await this.analyzeUserBehavior(userId);

      const campaign = this.createCampaign(userData, userBehavior);

      // Store campaign for performance tracking
      await db.collection('marketingCampaigns').add({
        userId,
        campaign,
        createdAt: admin.firestore.Timestamp.now(),
        status: 'pending'
      });

      return campaign;

    } catch (error) {
      console.error('❌ Campaign generation failed:', error);
      return null;
    }
  }

  static async getUserProfile(userId) {
    const userDoc = await db.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data() : {};
  }

  static async analyzeUserBehavior(userId) {
    const bookings = await db.collection('bookings')
      .where('userId', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    const behavior = {
      totalBookings: bookings.docs.length,
      avgSpend: 0,
      favoriteVenueType: null,
      lastBookingDays: 0,
      bookingFrequency: 0 // bookings per month
    };

    if (behavior.totalBookings > 0) {
      const recentBooking = bookings.docs[0];
      behavior.lastBookingDays = Math.floor(
        (new Date() - recentBooking.data().createdAt.toDate()) / (1000 * 60 * 60 * 24)
      );

      // Calculate average spend
      const totalSpend = bookings.docs.reduce((sum, doc) => sum + (doc.data().depositAmount || 0), 0);
      behavior.avgSpend = totalSpend / behavior.totalBookings;

      // Estimate monthly frequency
      if (behavior.totalBookings >= 2) {
        const firstBooking = bookings.docs[bookings.docs.length - 1].data().createdAt.toDate();
        const lastBooking = recentBooking.data().createdAt.toDate();
        const monthsDiff = (lastBooking - firstBooking) / (1000 * 60 * 60 * 24 * 30);
        behavior.bookingFrequency = behavior.totalBookings / Math.max(1, monthsDiff);
      }
    }

    return behavior;
  }

  static createCampaign(userData, behavior) {
    let campaignType = 'reengagement';
    let message = 'Welcome back! 👋';
    let offer = 'Book with us again soon!';

    // Determine campaign type based on behavior
    if (behavior.totalBookings === 0) {
      // First-time user
      campaignType = 'welcome';
      offer = 'Get 20% off your first booking!';
    } else if (behavior.lastBookingDays > 30) {
      // Lapsed user
      campaignType = 'reengagement';
      offer = 'We missed you! Book now and get a free drink';
    } else if (behavior.bookingFrequency < 0.5) {
      // Low frequency user
      campaignType = 'loyalty_upsell';
      offer = 'Join our loyalty program for exclusive perks!';
    } else {
      // High value user
      campaignType = 'vip_offer';
      offer = 'VIP access to our best tables - book now!';
    }

    return {
      type: campaignType,
      title: `Special offer for ${userData.name || 'you'}`,
      message,
      offer,
      discountAmount: this.calculateDiscount(behavior, campaignType),
      validUntil: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
      channels: ['push', 'email', 'in_app']
    };
  }

  static calculateDiscount(behavior, campaignType) {
    const baseDiscounts = {
      'welcome': 0.2, // 20%
      'reengagement': 0.15, // 15%
      'loyalty_upsell': 0.1, // 10%
      'vip_offer': 0.05 // 5%
    };

    return baseDiscounts[campaignType] || 0.1;
  }
}

module.exports = {
  VenueRecommender,
  WaitTimePredictor,
  PricingOptimizer,
  MarketingAutomator
};
