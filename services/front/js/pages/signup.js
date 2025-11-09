// Signup page JavaScript
document.addEventListener('DOMContentLoaded', function() {
    const form = document.getElementById('signup-form');
    
    if (form) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const formData = {
                firstName: form.firstName.value.trim(),
                lastName: form.lastName.value.trim(),
                email: form.email.value.trim(),
                password: form.password.value,
                confirmPassword: form.confirmPassword.value,
                city: form.city.value.trim(),
                country: form.country.value.trim(),
            };

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
        };            if (!validateForm(form, validationRules)) {
                return;
            }

            // Disable submit button
            const submitBtn = form.querySelector('button[type="submit"]');
            const originalText = submitBtn.textContent;
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin mr-2"></i>Inscription...';

            try {
                const response = await api.signup({
                    first_name: formData.firstName,
                    last_name: formData.lastName,
                    email: formData.email,
                    password1: formData.password,
                    password2: formData.confirmPassword,
                    city: formData.city,
                    country: formData.country
                });

                Toast.success('Inscription réussie ! Veuillez vous connecter.');
                
                // Redirect to login page
                setTimeout(() => {
                    window.location.href = 'login.html';
                }, 1500);

            } catch (error) {
                console.error('Signup error:', error);
                Toast.error(error.message || 'Erreur lors de l\'inscription');
            } finally {
                // Re-enable submit button
                submitBtn.disabled = false;
                submitBtn.textContent = originalText;
            }
        });
    }
});
