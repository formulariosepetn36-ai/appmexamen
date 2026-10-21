const Cloudflare = require('cloudflare');
const fs = require('fs');

// El token NUNCA vive en el archivo: se lee de la variable de entorno
// CLOUDFLARE_API_TOKEN (guardarla en .env, que git ya ignora).
if (!process.env.CLOUDFLARE_API_TOKEN) {
  console.error('Falta la variable de entorno CLOUDFLARE_API_TOKEN');
  process.exit(1);
}

const cf = new Cloudflare({
  apiToken: process.env.CLOUDFLARE_API_TOKEN
});

const accountId = '1304125146f00706da29b53e771ea660';

async function generarImagen() {
  try {
    console.log('Generando imagen con Cloudflare Workers AI...');
    
    const result = await cf.ai.run('@cf/black-forest-labs/flux-1-schnell', {
      account_id: accountId,
      prompt: 'realistic photo of a person filling out a registration form at a desk, warm lighting, professional, high quality'
    });
    
    // result es un Buffer
    fs.writeFileSync('C:\\Users\\ESTUDI~1\\AppData\\Local\\Temp\\opencode\\cloudflare_imagen.jpg', result);
    console.log('Imagen guardada exitosamente!');
    
  } catch (error) {
    console.error('Error:', error.message);
    if (error.errors) {
      console.error('Detalles:', JSON.stringify(error.errors, null, 2));
    }
  }
}

generarImagen();
