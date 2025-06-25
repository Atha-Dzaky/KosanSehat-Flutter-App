# app/ml_engine/meal_planner.py

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import json
import numpy as np
import random

class MealPlanner:
    def __init__(self, data_path):
        print("Menginisialisasi Meal Planner Engine...")
        self.df = self._load_and_process_data(data_path)
        self.tfidf, self.tfidf_matrix = self._build_model()
        print("✅ Meal Planner Engine siap digunakan.")

    def _load_and_process_data(self, data_path):
        print(f"Membaca dan memproses data dari '{data_path}'...")
        df_resto = pd.read_json(data_path, orient='records')
        
        rows = []
        for index, resto in df_resto.iterrows():
            if 'menu' in resto and isinstance(resto['menu'], list):
                for menu_item in resto['menu']:
                    row = {
                        'nama_restoran': resto.get('nama_restoran'), 'rating_restoran': resto.get('rating'),
                        'latitude': resto.get('latitude'), 'longitude': resto.get('longitude'),
                        'jam_buka': resto.get('jam_buka'), **menu_item
                    }
                    rows.append(row)
        
        df = pd.DataFrame(rows)
        
        df['Harga'] = pd.to_numeric(df['Harga'].astype(str).str.replace('.', '', regex=False), errors='coerce')
        df['kalori'] = pd.to_numeric(df['kalori'], errors='coerce')
        
        df.dropna(subset=['Harga', 'kalori', 'tags', 'Kategori'], inplace=True)

        df['Harga'] = df['Harga'].astype(np.int64)
        df['kalori'] = df['kalori'].astype(np.int64)
        
        df['alergen_seafood'] = df['tags'].apply(lambda x: 'alergen seafood' in x or 'seafood' in x if isinstance(x, list) else False)
        df['alergen_kacang'] = df['tags'].apply(lambda x: 'alergen kacang' in x if isinstance(x, list) else False)
        df['alergen_susu'] = df['tags'].apply(lambda x: 'alergen susu' in x if isinstance(x, list) else False)
        df['alergen_telur'] = df['tags'].apply(lambda x: 'alergen telur' in x if isinstance(x, list) else False)
        df['alergen_gluten'] = df['tags'].apply(lambda x: 'alergen gluten' in x if isinstance(x, list) else False)
        df['alergen_kedelai'] = df['tags'].apply(lambda x: 'alergen kedelai' in x if isinstance(x, list) else False)
        
        return df

    def _build_model(self):
        print("Membangun model TF-IDF...")
        self.df['fitur_model'] = self.df['tags'].apply(lambda x: ' '.join(x) if isinstance(x, list) else '')
        tfidf = TfidfVectorizer()
        tfidf_matrix = tfidf.fit_transform(self.df['fitur_model'])
        return tfidf, tfidf_matrix

    def _recommend_food(self, dataframe, target_kalori, preferensi, alergi, budget, top_n=10, w_taste=0.6, w_calorie=0.4):
        df_filtered = dataframe.copy()
        for a in alergi:
            alergen_col = f'alergen_{a.lower()}'
            if alergen_col in df_filtered.columns:
                df_filtered = df_filtered[~df_filtered[alergen_col]]
        
        df_filtered = df_filtered[df_filtered['Harga'] <= budget]
        
        if df_filtered.empty:
            return pd.DataFrame()

        filtered_indices = df_filtered.index
        user_pref_text = ' '.join(preferensi).lower()
        user_vector = self.tfidf.transform([user_pref_text])
        
        taste_scores = cosine_similarity(user_vector, self.tfidf_matrix[filtered_indices])
        
        if target_kalori > 0:
            calorie_diff = abs(df_filtered['kalori'] - target_kalori)
            calorie_scores = 1 / (1 + calorie_diff / target_kalori)
        else:
            calorie_scores = pd.Series([0] * len(df_filtered), index=df_filtered.index)
            
        final_scores = (w_taste * taste_scores.flatten()) + (w_calorie * calorie_scores.values)
        df_filtered['skor_akhir'] = final_scores
        return df_filtered.sort_values(by='skor_akhir', ascending=False).head(top_n)

    def _recommend_combo_meal(self, dataframe, target_kalori, preferensi, alergi, budget, w_taste=0.6, w_calorie=0.4):
        anchor_recs = self._recommend_food(dataframe, target_kalori, preferensi, alergi, budget, top_n=3, w_taste=w_taste, w_calorie=w_calorie)
        
        if anchor_recs.empty:
            return []

        anchor_dish = anchor_recs.sample(1).iloc[0]
        combo = [anchor_dish.to_dict()]
        
        gap_kalori = target_kalori - anchor_dish['kalori']
        sisa_budget = budget - anchor_dish['Harga']

        if gap_kalori < 100 or sisa_budget < 3000:
            return combo

        nama_restoran_anchor = anchor_dish['nama_restoran']
        df_complements = self.df[(self.df['nama_restoran'] == nama_restoran_anchor) & (self.df['Nama'] != anchor_dish['Nama'])].copy()
        
        kategori_pelengkap = ['minuman', 'nasi', 'lauk tambahan', 'sayur', 'cemilan', 'sambal', 'kerupuk', 'kuah']
        df_complements = df_complements[df_complements['Kategori'].str.lower().isin(kategori_pelengkap)]
        df_complements = df_complements[df_complements['Harga'] <= sisa_budget]

        if df_complements.empty:
            return combo

        df_complements['calorie_fit_score'] = abs(df_complements['kalori'] - gap_kalori)
        best_complement = df_complements.sort_values(by='calorie_fit_score').iloc[0]
        combo.append(best_complement.to_dict())
        return combo

    def create_daily_meal_plan(self, target_kalori_harian, preferensi, alergi, budget_harian):
        meal_plan = {}
        sisa_kalori = target_kalori_harian
        sisa_budget = budget_harian
        tag_utama_terpakai = []
        SARAPAN_PERCENT = 0.25
        MAKAN_SIANG_PERCENT = 0.40

        print("\n1. Merencanakan Sarapan...")
        df_sarapan = self.df[self.df['tags'].apply(lambda tags: 'sarapan' in tags if isinstance(tags, list) else False)].copy()
    
        rekomendasi_sarapan = self._recommend_food(df_sarapan, target_kalori_harian * SARAPAN_PERCENT, preferensi, alergi, budget_harian * SARAPAN_PERCENT, top_n=5)
        
        if not rekomendasi_sarapan.empty:
            pilihan = rekomendasi_sarapan.sample(1).iloc[0]
            meal_plan['sarapan'] = [pilihan.to_dict()]
            sisa_kalori -= pilihan['kalori']
            sisa_budget -= pilihan['Harga']
            for tag in pilihan['tags']:
                if tag in ['bubur', 'soto', 'lontong', 'ketan', 'roti']:
                    tag_utama_terpakai.append(tag)
                    break
            print(f"-> Sarapan terpilih: {pilihan['Nama']}")
        else:
            meal_plan['sarapan'] = []
            print("-> Tidak ditemukan sarapan yang cocok.")

        # --- MAKAN SIANG ---
        print("\n2. Merencanakan Makan Siang...")
        df_siang = self.df[self.df['tags'].apply(lambda tags: 'maincourse' in tags if isinstance(tags, list) else False)].copy()
        if tag_utama_terpakai:
            df_siang = df_siang[df_siang['tags'].apply(lambda tags: not any(t in tags for t in tag_utama_terpakai))]
        
        combo_siang = self._recommend_combo_meal(df_siang, target_kalori_harian * MAKAN_SIANG_PERCENT, preferensi, alergi, budget_harian * MAKAN_SIANG_PERCENT)
        meal_plan['makan_siang'] = combo_siang
        
        if combo_siang:
            print(f"-> Paket Makan Siang terpilih:")
            for item in combo_siang:
                sisa_kalori -= item['kalori']
                sisa_budget -= item['Harga']
                print(f"   - {item['Nama']}")
                for tag in item.get('tags', []):
                    if tag in ['ayam', 'sate', 'bakso', 'rawon', 'gulai', 'ikan', 'bebek', 'geprek', 'penyetan']:
                        tag_utama_terpakai.append(tag)
                        break
        else:
            print("-> Tidak ditemukan makan siang yang cocok.")

        # --- MAKAN MALAM ---
        print("\n3. Merencanakan Makan Malam...")
        df_malam_candidates = self.df[self.df['tags'].apply(lambda tags: 'maincourse' in tags if isinstance(tags, list) else False)].copy()
        if tag_utama_terpakai:
            df_malam_candidates = df_malam_candidates[df_malam_candidates['tags'].apply(lambda tags: not any(t in tags for t in tag_utama_terpakai))]

        target_kalori_malam = sisa_kalori if sisa_kalori > 0 else 0
        budget_malam = sisa_budget if sisa_budget > 0 else 0
        
        df_malam_strict = pd.DataFrame()
        if target_kalori_malam > 0 and not df_malam_candidates.empty:
            min_kalori, max_kalori = target_kalori_malam * 0.75, target_kalori_malam * 1.25
            print(f"   Mencari makan malam dengan rentang kalori ketat: {min_kalori:.0f} - {max_kalori:.0f} kkal")
            df_malam_strict = df_malam_candidates[(df_malam_candidates['kalori'] >= min_kalori) & (df_malam_candidates['kalori'] <= max_kalori)]
        
        if not df_malam_strict.empty:
            print("   -> Kandidat ditemukan dalam rentang kalori ketat.")
            combo_malam = self._recommend_combo_meal(df_malam_strict, target_kalori_malam, preferensi, alergi, budget_malam, w_taste=0.3, w_calorie=0.7)
        else:
            print("   -> Pencarian ketat gagal. Mencoba pencarian longgar...")
            combo_malam = self._recommend_combo_meal(df_malam_candidates, target_kalori_malam, preferensi, alergi, budget_malam, w_taste=0.3, w_calorie=0.7)
        
        meal_plan['makan_malam'] = combo_malam
        if combo_malam:
            print(f"-> Paket Makan Malam terpilih:")
            for item in combo_malam:
                print(f"   - {item['Nama']}")
        else:
            print("-> Tidak ditemukan makan malam yang cocok.")
            
        for meal_type, meal_list in meal_plan.items():
            if meal_list:
                temp_df = pd.DataFrame(meal_list)
                json_string = temp_df.to_json(orient='records')
                cleaned_list = json.loads(json_string)
                meal_plan[meal_type] = cleaned_list
                
        return meal_plan