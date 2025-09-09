// Login page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('login-form');
    
    if (form) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const email = form.email.value.trim();
            const password = form.password.value;

            // Validation rules
        const validationRules = {
            email: [
                { validator: ValidationRules.required, message: 'Correo electrónico requerido.' },
                { validator: ValidationRules.email, message: 'Correo electrónico inválido.' }
            ],
            password: [
                { validator: ValidationRules.required, message: 'Contraseña requerida.' }
            ]
        };            if (!validateForm(form, validationRules)) {
                return;
            }

            // Disable submit button
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Connexion...';

            try {
                const response = await api.login({ email, password });

                // Store auth data
                Auth.login(response.token, response.user);
                
                Toast.success('Connexion réussie ! Redirection...');
                
                // Redirect to dashboard
                setTimeout(() => {
                    window.location.href = 'dashboard.html';
                }, 1500);

            } catch (error) {
                console.error('Login error:', error);
                Toast.error(error.message || 'Credenciales inválidas');
            } finally {
                // Re-enable submit button
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
            }
        });
    }
});
