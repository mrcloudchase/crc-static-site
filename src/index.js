document.addEventListener('DOMContentLoaded', () => {
    // Smooth scroll for internal links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function(e) {
            e.preventDefault();
            document.querySelector(this.getAttribute('href')).scrollIntoView({
                behavior: 'smooth'
            });
        });
    });

    // Basic form validation (can be expanded)
    const form = document.getElementById('contact-form');
    form.addEventListener('submit', (e) => {
        if (!form.checkValidity()) {
            e.preventDefault();
            alert('Please fill out all required fields.');
        }
    });
});
