// Validation utility to check form inputs
class Validation {
    static isEmail(email) {
        const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return re.test(email);
    }
    
    static isRequired(value) {
        return value && value.trim().length > 0;
    }
    
    static minLength(value, length) {
        return value && value.length >= length;
    }
    
    static validateForm(formElement, rules) {
        let isValid = true;
        const errors = {};
        
        for (const [fieldName, fieldRules] of Object.entries(rules)) {
            const field = formElement[fieldName];
            if (!field) continue;
            
            const value = field.value;
            const errorElement = document.getElementById(`error-${fieldName}`);
            
            for (const rule of fieldRules) {
                if (!rule.validator(value)) {
                    if (errorElement) errorElement.textContent = rule.message;
                    errors[fieldName] = rule.message;
                    isValid = false;
                    break;
                } else {
                    if (errorElement) errorElement.textContent = '';
                }
            }
        }
        
        return { isValid, errors };
    }
}

window.Validation = Validation;
