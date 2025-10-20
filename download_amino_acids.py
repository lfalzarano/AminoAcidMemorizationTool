import requests
from bs4 import BeautifulSoup
import os
from pathlib import Path
import time

# Standard amino acids
AMINO_ACIDS = [
    "Alanine", "Arginine", "Asparagine", "Aspartic acid",
    "Cysteine", "Glutamic acid", "Glutamine", "Glycine",
    "Histidine", "Isoleucine", "Leucine", "Lysine",
    "Methionine", "Phenylalanine", "Proline", "Serine",
    "Threonine", "Tryptophan", "Tyrosine", "Valine"
]

def get_skeletal_formula_image(amino_acid_name):
    """Scrape Wikipedia page to find the skeletal formula image"""
    try:
        # Fetch the Wikipedia page
        url = f"https://en.wikipedia.org/wiki/{amino_acid_name.replace(' ', '_')}"
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        }
        
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Look for the specific pattern: figure with img, followed by div containing "Skeletal formula"
        figures = soup.find_all('figure')
        
        for fig in figures:
            # Get the img from the figure
            img = fig.find('img')
            if not img or not img.get('src'):
                continue
            
            # Look for the sibling div with "Skeletal formula" caption
            next_div = fig.find_next('div')
            if next_div:
                div_text = next_div.get_text().lower()
                if 'skeletal formula' in div_text or 'skeletal form' in div_text:
                    img_url = img['src']
                    # Convert to full URL if protocol-relative
                    if img_url.startswith('//'):
                        img_url = 'https:' + img_url
                    elif img_url.startswith('/'):
                        img_url = 'https://en.wikipedia.org' + img_url
                    return img_url
        
        return None
    
    except Exception as e:
        print(f"  Error scraping page: {e}")
        return None

def download_image(img_url):
    """Download image from URL"""
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
            "Referer": "https://en.wikipedia.org/"
        }
        
        response = requests.get(img_url, headers=headers, timeout=10)
        response.raise_for_status()
        
        return response.content
    
    except Exception as e:
        print(f"  Error downloading image: {e}")
        return None

def download_amino_acid_structures(output_dir="amino_acids"):
    """Download skeletal formula images for all amino acids"""
    Path(output_dir).mkdir(exist_ok=True)
    
    print(f"Downloading amino acid skeletal formulas to '{output_dir}/' directory...\n")
    
    for amino_acid in AMINO_ACIDS:
        print(f"Processing {amino_acid}...", end=" ")
        
        # Get the image URL from Wikipedia
        img_url = get_skeletal_formula_image(amino_acid)
        
        if not img_url:
            print("✗ No skeletal formula found")
            continue
        
        # Download the image
        img_data = download_image(img_url)
        
        if img_data:
            try:
                # Determine file extension - check actual content first
                if img_data.startswith(b'<?xml') or img_data.startswith(b'<svg'):
                    ext = 'svg'
                elif b'PNG' in img_data[:20]:
                    ext = 'png'
                elif b'WEBP' in img_data[:20]:
                    ext = 'webp'
                else:
                    # Fallback to URL extension
                    if '.svg' in img_url.lower():
                        ext = 'svg'
                    elif '.webp' in img_url.lower():
                        ext = 'webp'
                    else:
                        ext = 'png'
                
                filename = f"{amino_acid.replace(' ', '_')}.{ext}"
                filepath = os.path.join(output_dir, filename)
                
                with open(filepath, "wb") as f:
                    f.write(img_data)
                
                print(f"✓ Downloaded ({ext})")
                time.sleep(0.5)  # Be respectful to Wikipedia servers
            
            except Exception as e:
                print(f"✗ Failed to save: {e}")
        else:
            print("✗ Could not download image")

if __name__ == "__main__":
    # Check for BeautifulSoup
    try:
        import bs4
    except ImportError:
        print("BeautifulSoup4 is required. Install it with:")
        print("pip install beautifulsoup4")
        exit(1)
    
    download_amino_acid_structures()
    print("\nDownload complete!")