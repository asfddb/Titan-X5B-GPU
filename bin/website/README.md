# Titan X5-B GPU — Website Deployment

This directory contains the static landing page for the Titan X5-B GPU IP commercialization. 
It is built using plain HTML and Tailwind CSS (via CDN) to ensure maximum compatibility and zero build steps.

## Deployment Instructions

You can host this website for free using **GitHub Pages** or **Cloudflare Pages**.

### Option A: GitHub Pages
1. Go to your GitHub repository settings.
2. Click on **Pages** in the left sidebar.
3. Under **Build and deployment**, select **Deploy from a branch**.
4. Select the `master` branch (or whichever branch you merge this into).
5. Change the folder from `/ (root)` to `/website`.
6. Click **Save**. Your site will be live at `https://asfddb.github.io/Titan-X5B-GPU/website/`.

### Option B: Cloudflare Pages (Recommended for Custom Domains)
1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/) and go to **Pages**.
2. Click **Connect to Git** and authorize your GitHub account.
3. Select the `Titan-X5B-GPU` repository.
4. In the build settings:
   - Framework preset: None
   - Build command: *(leave blank)*
   - Build output directory: `website`
5. Click **Save and Deploy**.
6. Once deployed, you can assign your custom domain (e.g., `titan-gpu.com`) in the Custom Domains tab.
