// Signup page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('signup-form');
    
    if (form) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const first_name =  form.firstName.value.trim()
            const last_name = form.lastName.value.trim()
            const email = form.email.value.trim()
            const password1 = form.password.value
            const password2 = form.confirmPassword.value
            const city = form.city.value.trim()
            const country = form.country.value.trim()

            // Validation rules
            const validationRules = {
                firstName: [
                    { validator: ValidationRules.required, message: 'Nombre requerido.' }
                ],
                lastName: [
                    { validator: ValidationRules.required, message: 'Apellido requerido.' }
                ],
                email: [
                    { validator: ValidationRules.required, message: 'Correo electrónico requerido.' },
                    { validator: ValidationRules.email, message: 'Correo electrónico inválido.' }
                ],
                password: [
                    { validator: ValidationRules.required, message: 'Contraseña requerida.' },
                    { validator: ValidationRules.minLength(6), message: 'Mínimo 6 caracteres.' }
                ],
                confirmPassword: [
                    { validator: ValidationRules.required, message: 'Confirmación requerida.' },
                    { validator: ValidationRules.match(form.password.value), message: 'Las contraseñas no coinciden.' }
                ],
                city: [
                    { validator: ValidationRules.required, message: 'Ciudad requerida.' }
                ],
                country: [
                    { validator: ValidationRules.required, message: 'País requerido.' }
                ]
            };  

            if (!validateForm(form, validationRules)) {
                return;
            }

            // Disable submit button
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Registrando...';

            try {
                const response = await api.signup({ first_name, last_name, email, password1, password2, city, country });

                Toast.success('¡Registro exitoso! Por favor, inicie sesión.');
                
                // Redirect to login page
                setTimeout(() => {
                    window.location.href = 'login.html';
                }, 1500);

            } catch (error) {
                console.error('Signup error:', error);
                Toast.error(error.message || 'Error durante el registro');
            } finally {
                // Re-enable submit button
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
            }
        });
    }
});
