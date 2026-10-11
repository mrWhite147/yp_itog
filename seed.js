// seed_products.js
const API = 'http://127.0.0.1:8090/api';

async function post(collection, data) {
  try {
    const res = await fetch(`${API}/collections/${collection}/records`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      console.error(`Ошибка в ${collection}:`, await res.text());
      return null;
    }
    return await res.json();
  } catch (e) {
    console.error('Ошибка сети:', e.message);
    return null;
  }
}

async function run() {
  console.log('⏳ Загружаем бренды и категории...');

  // 1. Создаем бренды (если еще нет)
  const apple = await post('manufacturers', { name: 'Apple', foundedYear: 1976, country: 'США' });
  const samsung = await post('manufacturers', { name: 'Samsung', foundedYear: 1938, country: 'Южная Корея' });
  const sony = await post('manufacturers', { name: 'Sony', foundedYear: 1946, country: 'Япония' });
  const asus = await post('manufacturers', { name: 'Asus', foundedYear: 1989, country: 'Тайвань' });
  const xiaomi = await post('manufacturers', { name: 'Xiaomi', foundedYear: 2010, country: 'Китай' });

  // 2. Создаем категории
  const phones = await post('categories', { name: 'Смартфоны' });
  const laptops = await post('categories', { name: 'Ноутбуки' });
  const audio = await post('categories', { name: 'Аудио и наушники' });
  const tvs = await post('categories', { name: 'Телевизоры' });
  const gaming = await post('categories', { name: 'Гейминг' });

  console.log('⏳ Загружаем товары в каталог...');

  const products = [
    // Apple
    { name: 'iPhone 15 Pro Max 256GB', sku: 'APL-15PM-256', price: 135000, stockCount: 12, manufacturerId: apple?.id || '', categoryIds: [phones?.id || ''] },
    { name: 'MacBook Pro 16" M3 Max', sku: 'MAC-P16-M3', price: 285000, stockCount: 3, manufacturerId: apple?.id || '', categoryIds: [laptops?.id || ''] }, // Дефицит!
    { name: 'AirPods Max Space Gray', sku: 'APL-MAX-SG', price: 62000, stockCount: 8, manufacturerId: apple?.id || '', categoryIds: [audio?.id || ''] },
    { name: 'iPad Pro 12.9" M2', sku: 'APL-IPAD-12', price: 110000, stockCount: 6, manufacturerId: apple?.id || '', categoryIds: [phones?.id || ''] },

    // Samsung
    { name: 'Samsung Galaxy S24 Ultra', sku: 'SAM-S24U-512', price: 118000, stockCount: 15, manufacturerId: samsung?.id || '', categoryIds: [phones?.id || ''] },
    { name: 'Samsung Galaxy Book 4 Ultra', sku: 'SAM-GB4-U', price: 165000, stockCount: 4, manufacturerId: samsung?.id || '', categoryIds: [laptops?.id || ''] }, // Дефицит!
    { name: 'Samsung Galaxy Buds 2 Pro', sku: 'SAM-BUDS-2P', price: 15000, stockCount: 25, manufacturerId: samsung?.id || '', categoryIds: [audio?.id || ''] },

    // Sony
    { name: 'Sony PlayStation 5 Slim', sku: 'SON-PS5-SLIM', price: 58000, stockCount: 2, manufacturerId: sony?.id || '', categoryIds: [gaming?.id || ''] }, // Дефицит!
    { name: 'Sony WH-1000XM5 Black', sku: 'SON-WH5-BLK', price: 36000, stockCount: 18, manufacturerId: sony?.id || '', categoryIds: [audio?.id || ''] },
    { name: 'Sony Bravia 4K OLED 65"', sku: 'SON-TV-65OLED', price: 195000, stockCount: 3, manufacturerId: sony?.id || '', categoryIds: [tvs?.id || ''] }, // Дефицит!

    // Asus & Xiaomi
    { name: 'Asus ROG Strix SCAR 18', sku: 'ASUS-ROG-18', price: 310000, stockCount: 2, manufacturerId: asus?.id || '', categoryIds: [laptops?.id || '', gaming?.id || ''] }, // Дефицит!
    { name: 'Xiaomi 14 Ultra Photography Kit', sku: 'XIA-14U-KIT', price: 98000, stockCount: 7, manufacturerId: xiaomi?.id || '', categoryIds: [phones?.id || ''] },
  ];

  for (const p of products) {
    await post('products', p);
  }

  console.log('\n🎉 Каталог успешно наполнен! Все 12 товаров созданы.');
}

run();