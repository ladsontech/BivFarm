import os
import time
import urllib.request

images = {
    'p1_maize.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Maize_ears.JPG/600px-Maize_ears.JPG',
    'p2_beans.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Kidney_beans.jpg/600px-Kidney_beans.jpg',
    'p3_rice.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Rice_01.jpg/600px-Rice_01.jpg',
    'p4_groundnuts.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Peanuts.jpg/600px-Peanuts.jpg',
    'p5_coffee.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Roasted_coffee_beans.jpg/600px-Roasted_coffee_beans.jpg',
    'p6_goats.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Flock_of_goats.jpg/600px-Flock_of_goats.jpg',
    'p7_tomatoes.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tomato_je.jpg/600px-Tomato_je.jpg',
    'p8_onions.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Onion_on_White.JPG/600px-Onion_on_White.JPG',
    'p9_soybeans.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Soybean_seed.jpg/600px-Soybean_seed.jpg',
    'p10_cassava.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Cassava.jpg/600px-Cassava.jpg',
    'p11_poultry.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Free_range_chickens_in_grass.jpg/600px-Free_range_chickens_in_grass.jpg',
    'p12_mangoes.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Hapus_Mango.jpg/600px-Hapus_Mango.jpg',
    'p13_sweet_potatoes.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/Sweet_potato.jpg/600px-Sweet_potato.jpg',
    'p14_cattle.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Cow_female_black_white.jpg/600px-Cow_female_black_white.jpg',
    'p15_cocoa.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Cocoa_Beans.jpg/600px-Cocoa_Beans.jpg',
    'p16_pineapples.jpg': 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cb/Pineapple_and_cross_section.jpg/600px-Pineapple_and_cross_section.jpg'
}

base_dir = r"e:\productivity\BivFarm\assets\images\demo"
os.makedirs(base_dir, exist_ok=True)

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) BivFarmApp/1.0'}

for filename, url in images.items():
    filepath = os.path.join(base_dir, filename)
    if not os.path.exists(filepath):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req) as response, open(filepath, 'wb') as out_file:
                out_file.write(response.read())
            print(f"Downloaded {filename}")
            time.sleep(1)  # avoid rate limits
        except Exception as e:
            print(f"Failed to download {filename}: {e}")
    else:
        print(f"Skipped {filename} (already exists)")

print("Done downloading images.")
