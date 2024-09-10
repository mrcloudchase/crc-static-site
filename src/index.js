// Smooth scrolling for internal links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        document.querySelector(this.getAttribute('href')).scrollIntoView({
            behavior: 'smooth'
        });
    });
});

document.addEventListener("DOMContentLoaded", function() {
    fetch('https://<your-function-app-name>.azurewebsites.net/api/PageViewCounter')
    .then(response => response.text())
    .then(data => {
        document.getElementById('page-view-counter').textContent = `Page views: ${data}`;
    })
    .catch(error => console.error('Error fetching page views:', error));
});
