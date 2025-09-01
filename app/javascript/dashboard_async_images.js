document.addEventListener('DOMContentLoaded', function() {
  function pollImageStatus() {
    var productId = document.body.dataset.productId;
    var marketId = document.body.dataset.marketId;
    fetch(`/dashboard/image_status?product_id=${productId}&market_id=${marketId}`)
      .then(response => response.json())
      .then(data => {
        if (data.status === 'ready') {
          var imgBlock = document.getElementById('image-block');
          imgBlock.innerHTML = `<img src="${data.url}" id="product-image" />`;
        } else {
          setTimeout(pollImageStatus, 2000);
        }
      });
  }
  pollImageStatus();
});
