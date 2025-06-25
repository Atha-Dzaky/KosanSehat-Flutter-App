# run.py

from app import create_app

# Membuat instance aplikasi menggunakan factory function kita
app = create_app()

if __name__ == '__main__':
    # Menjalankan server pengembangan Flask
    # host='0.0.0.0' agar bisa diakses dari luar container/jaringan lokal
    # debug=True agar server otomatis restart saat ada perubahan kode
    app.run(debug=True, host='0.0.0.0', port=8080)