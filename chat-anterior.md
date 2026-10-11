Listed directory workflows
Created build-apk.yml
Ran command: `git remote -v`
Ran command: `git status --short`

Ya dejé creado el archivo automatizado [`.github/workflows/build-apk.yml`](file:///home/johndeivid/buana-vpad/.github/workflows/build-apk.yml). Este archivo le enseña a GitHub cómo compilar el APK sin necesidad de firmas secretas ni configuraciones complejas.

Ojo con un detalle importante: actualmente tu repositorio local apunta al GitHub del autor original (`isaui/buana-vpad`). Para subirlo a **tu** GitHub y que se compile gratis, sigue estos pasos:

---

### Paso 1: Crear un nuevo repositorio en tu GitHub
1. Abre [github.com/new](https://github.com/new) en tu navegador.
2. Nómbralo como quieras (por ejemplo: `buana-vpad`).
3. Puedes dejarlo en **Público** o **Privado**.
4. **No** marques la casilla de "Add a README" ni nada parecido (déjalo vacío).
5. Haz clic en **Create repository**.

---

### Paso 2: Ejecutar estos comandos en tu terminal

Abre tu terminal dentro de la carpeta del proyecto y ejecuta estos comandos uno por uno (cambia `TU_USUARIO_DE_GITHUB` por tu nombre de usuario real en GitHub):

```bash
# 1. Asegúrate de estar en la raíz del proyecto
cd /home/johndeivid/buana-vpad

# 2. Guarda todos los cambios que hicimos (FPV + Visor 3D + Build)
git add .
git commit -m "feat: soporte FPV completo, visor 3D y workflow de APK"

# 3. Cambia la dirección remota para que apunte a TU cuenta de GitHub
git remote set-url origin https://github.com/TU_USUARIO_DE_GITHUB/buana-vpad.git

# 4. Sube el código a tu GitHub
git push -u origin main
```
*(Si tu rama actual se llama `master` en lugar de `main`, cambia la última línea a `git push -u origin master`).*

---

### Paso 3: Disparar la compilación con 1 clic en GitHub

Una vez subido el código:

1. Entra a tu repositorio en GitHub desde el navegador: `https://github.com/TU_USUARIO_DE_GITHUB/buana-vpad`.
2. Haz clic en la pestaña **Actions** (arriba, entre *Pull requests* y *Projects*).
3. En la barra lateral izquierda verás el flujo llamado:  
   👉 **"Compilar APK en la Nube"**
4. A la derecha verás un botón que dice **"Run workflow"**. Haz clic en él y confirma presionando el botón verde **"Run workflow"**.

---

### Paso 4: Descargar el APK e instalarlo

1. Verás que aparece una tarea corriendo con un círculo girando. Los servidores de GitHub descargarán Flutter, compilarán el APK y prepararán el archivo (tarda unos **3 a 5 minutos**).
2. Cuando el círculo se vuelva verde (✅):
   - Haz clic sobre la tarea completada.
   - Baja hasta la sección **Artifacts** (al final de la página).
   - Verás un archivo llamado **`BuanaVPad-Debug-APK`**.
3. Haz clic en él para descargarlo en tu móvil (o en tu PC y pasártelo por Telegram/WhatsApp/cable).
4. Ábrelo en tu teléfono Android, acepta el aviso de fuentes desconocidas y ¡listo para volar!