import os
import time
import urllib.request

images = {
    'p1_maize.jpg': 'https://loremflickr.com/600/600/maize,corn',
    'p2_beans.jpg': 'https://loremflickr.com/600/600/beans',
    'p3_rice.jpg': 'https://loremflickr.com/600/600/rice',
    'p4_groundnuts.jpg': 'https://loremflickr.com/600/600/peanuts',
    'p6_goats.jpg': 'https://loremflickr.com/600/600/goats',
    'p9_soybeans.jpg': 'https://loremflickr.com/600/600/soybeans',
    'p10_cassava.jpg': 'https://loremflickr.com/600/600/cassava',
    'p11_poultry.jpg': 'https://loremflickr.com/600/600/chickens',
    'p13_sweet_potatoes.jpg': 'https://loremflickr.com/600/600/sweetpotatoes',
    'p14_cattle.jpg': 'https://loremflickr.com/600/600/cattle,cows',
    'p15_cocoa.jpg': 'https://loremflickr.com/600/600/cocoa,beans'
}

base_dir = r"e:\productivity\BivFarm\assets\images\demo"

headers = {'User-Agent': 'Mozilla/5.0'}

for filename, url in images.items():
    filepath = os.path.join(base_dir, filename)
    if not os.path.exists(filepath):
        try:
            req = urllib.request.Request(url, headers=headers)
            with urllib.request.urlopen(req) as response, open(filepath, 'wb') as out_file:
                out_file.write(response.read())
            print(f"Downloaded {filename}")
            time.sleep(0.5)
        except Exception as e:
            print(f"Failed to download {filename}: {e}")
    else:
        print(f"Skipped {filename} (already exists)")

print("Done downloading images.")
