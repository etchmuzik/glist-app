// Database Seeding Script for Glist Firebase Setup
// Run with: node seed_database.js

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./path/to/serviceAccountKey.json'); // You'll need to add this
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'glist-6e64f'
});

const db = admin.firestore();

async function seedVenues() {
  console.log('🌱 Seeding database with Dubai venues from VenueData...');

  const dubaiVenues = [
    {
      id: 'white-dubai',
      name: 'White Dubai',
      type: 'Nightclub',
      location: 'Meydan Racecourse',
      district: 'meydan',
      description: "Dubai's ultimate outdoor rooftop nightlife experience. Known for its incredible light shows and top-tier DJ lineups.",
      rating: 4.8,
      price: '$$$$',
      dressCode: 'Smart Elegant',
      imageName: 'venue_white',
      tags: ['Rooftop', 'Outdoor', 'Hip Hop', 'Electronic'],
      latitude: 25.1558,
      longitude: 55.3003,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: "Government-issued ID required • Security bag checks • Respectful conduct enforced",
      weeklySchedule: { 'Saturday': 'URBN (Hip Hop)', 'Tuesday': 'Ladies Night' },
      isTrending: true,
      tables: [
        { id: 'table-vip-1', name: 'VIP Table 1', capacity: 6, minimumSpend: 2000, isAvailable: true },
        { id: 'table-vip-2', name: 'VIP Table 2', capacity: 8, minimumSpend: 3000, isAvailable: true },
        { id: 'table-sky', name: 'Sky Terrace', capacity: 4, minimumSpend: 1500, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'soho-garden',
      name: 'Soho Garden',
      type: 'Nightclub complex',
      location: 'Meydan Racecourse',
      district: 'meydan',
      description: 'A massive complex featuring multiple venues including Code, Soho Garden DXB, and more. The heart of Dubai\'s party scene.',
      rating: 4.7,
      price: '$$$',
      dressCode: 'Smart Casual',
      imageName: 'venue_soho',
      tags: ['Complex', 'House', 'Techno', 'Garden'],
      latitude: 25.1560,
      longitude: 55.2990,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Smart casual dress code • Entry subject to sobriety checks • Valid ID required',
      weeklySchedule: { 'Friday': 'Playground (Techno)', 'Saturday': 'Soho Saturdays' },
      isTrending: true,
      tables: [
        { id: 'table-garden-1', name: 'Garden Table', capacity: 8, minimumSpend: 2500, isAvailable: true },
        { id: 'table-code-1', name: 'Code VIP', capacity: 6, minimumSpend: 1800, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'blu-dubai',
      name: 'BLU Dubai',
      type: 'Nightclub',
      location: 'V Hotel, Al Habtoor City',
      district: 'alHabtoor',
      description: 'A high-energy nightclub known for its celebrity appearances, state-of-the-art sound system, and luxurious atmosphere.',
      rating: 4.6,
      price: '$$$$',
      dressCode: 'Glamorous',
      imageName: 'venue_blu',
      tags: ['Luxury', 'Hip Hop', 'Live Shows'],
      latitude: 25.1856,
      longitude: 55.2583,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'VIP tables held for 15 minutes past booking • ID and age verification at door',
      tables: [
        { id: 'table-blu-vip-1', name: 'BLU VIP', capacity: 8, minimumSpend: 3000, isAvailable: true },
        { id: 'table-blu-rooftop', name: 'Rooftop Table', capacity: 6, minimumSpend: 2200, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'one-oak-dubai',
      name: '1 OAK Dubai',
      type: 'Nightclub',
      location: 'JW Marriott Marquis',
      district: 'downtown',
      description: 'One Of A Kind. The Dubai outpost of the famous New York nightclub, offering a chic and exclusive clubbing experience.',
      rating: 4.5,
      price: '$$$$',
      dressCode: 'Smart Elegant',
      imageName: 'venue_1oak',
      tags: ['Exclusive', 'Hip Hop', 'Celebrity Spot'],
      latitude: 25.1855,
      longitude: 55.2580,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Entry requires smart attire and matching ID; re-entry not guaranteed during peak hours',
      tables: [
        { id: 'table-1oak-vip', name: '1 OAK VIP', capacity: 6, minimumSpend: 2500, isAvailable: true },
        { id: 'table-1oak-bar', name: 'Bar Area', capacity: 4, minimumSpend: 1500, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'cove-beach',
      name: 'Cove Beach',
      type: 'Beach Club',
      location: 'Bluewaters Island',
      district: 'bluewaters',
      description: 'A stunning beach club with a Mediterranean vibe, featuring a pool, beach access, and a lively party atmosphere day and night.',
      rating: 4.6,
      price: '$$$',
      dressCode: 'Beach Chic',
      imageName: 'venue_cove',
      tags: ['Beach', 'Pool', 'Day Party', 'Sunset'],
      latitude: 25.0785,
      longitude: 55.1218,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Poolside safety team on-site • Sun-protection and hydration encouraged • ID check at entry',
      tables: [
        { id: 'table-beach-1', name: 'Beach Table', capacity: 4, minimumSpend: 1200, isAvailable: true },
        { id: 'table-poolside', name: 'Poolside Cabana', capacity: 6, minimumSpend: 1800, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'sky-20',
      name: 'Sky 2.0',
      type: 'Nightclub',
      location: 'Dubai Design District',
      district: 'd3',
      description: 'A revolutionary standalone nightclub in the heart of D3, known for its interactive design and grand scale entertainment.',
      rating: 4.9,
      price: '$$$$',
      dressCode: 'Dress to Impress',
      imageName: 'venue_sky',
      tags: ['Open Air', 'Design', 'Show', 'Architecture'],
      latitude: 25.1872,
      longitude: 55.2980,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Open-air venue; weather-related closures possible • ID required • Bag check at entry',
      tables: [
        { id: 'table-sky-vip', name: 'Sky VIP', capacity: 10, minimumSpend: 4000, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'billionaire-dubai',
      name: 'Billionaire Dubai',
      type: 'Dinner & Show',
      location: 'Taj Hotel',
      district: 'downtown',
      description: 'A unique dining and entertainment experience featuring spectacular live shows and Italian & New Asian cuisine.',
      rating: 4.7,
      price: '$$$$$',
      dressCode: 'Formal',
      imageName: 'venue_billionaire',
      tags: ['Dinner Show', 'Luxury', 'Performance'],
      latitude: 25.1944,
      longitude: 55.2753,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Dinner show requires seated arrivals • ID check and smart attire enforced',
      tables: [
        { id: 'table-dinner-show', name: 'Show Table', capacity: 4, minimumSpend: 5000, isAvailable: true }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    },
    {
      id: 'ce-la-vi',
      name: 'Ce La Vi',
      type: 'Lounge & Skybar',
      location: 'Address Sky View',
      district: 'downtown',
      description: 'Iconic rooftop venue offering breathtaking views of the Burj Khalifa, perfect for sunset drinks and evening vibes.',
      rating: 4.8,
      price: '$$$$',
      dressCode: 'Smart Casual',
      imageName: 'venue_celavi',
      tags: ['View', 'Rooftop', 'Lounge', 'Fine Dining'],
      latitude: 25.1972,
      longitude: 55.2744,
      isActive: true,
      isVerified: true,
      minimumAge: 21,
      safetyMessage: 'Rooftop safety briefings in effect • ID required • Age 21+ after 8pm',
      weeklySchedule: { 'Wednesday': 'Ladies Night', 'Friday': 'Sky High Brunch' },
      tables: [
        { id: 'table-rooftop-1', name: 'Rooftop Table', capacity: 6, minimumSpend: 2500, isAvailable: true },
        { id: 'table-lounge', name: 'Lounge Area', capacity: 4, minimumSpend: 1800, isAvailable: true }
      ],
      bottleMenu: [
        { name: 'Moet & Chandon', price: 1200, type: 'Champagne' },
        { name: 'Hendricks', price: 1400, type: 'Gin' }
      ],
      createdAt: admin.firestore.Timestamp.fromDate(new Date()),
      updatedAt: admin.firestore.Timestamp.fromDate(new Date())
    }
  ];

  for (const venueData of dubaiVenues) {
    const venueRef = db.collection('venues').doc(venueData.id);
    await venueRef.set(venueData);
    console.log(`✅ Added: ${venueData.name}`);
  }

  console.log('🎉 Database seeded successfully with all Dubai venues!');
}

async function setupSecurityRules() {
  console.log('🔒 Security rules and indexes will be deployed via Firebase CLI:');
  console.log('firebase deploy --only firestore:rules,firestore:indexes,storage');
}

async function main() {
  try {
    await seedVenues();
    await setupSecurityRules();
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Only run if called directly
if (require.main === module) {
  main();
}

module.exports = { seedVenues };
