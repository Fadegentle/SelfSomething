# 批量删除动态

油猴脚本：https://greasyfork.org/zh-CN/scripts/387046-%E6%8A%BD%E5%A5%96%E5%8A%A8%E6%80%81%E5%88%A0%E9%99%A4-%E5%8F%96%E5%85%B3

# 批量取消关注

油猴脚本：https://greasyfork.org/zh-CN/scripts/428895-bilibili-%E5%85%B3%E6%B3%A8%E7%AE%A1%E7%90%86%E5%99%A8

# 批量取消订阅收藏

油猴脚本：https://greasyfork.org/zh-CN/scripts/486323-%E5%93%94%E5%93%A9%E5%93%94%E5%93%A9%E8%AE%A2%E9%98%85%E7%AE%A1%E7%90%86-%E6%89%B9%E9%87%8F%E5%8F%96%E6%B6%88%E8%AE%A2%E9%98%85%E5%90%88%E9%9B%86

# 批量取消收藏

收藏页 - F12控制台：

```js
(function batdo(){
    console.log('批量操作');
    $('.do-batch').click();
    setTimeout(function() {
        console.log('全选');
        $('.icon-selece-all').click();
        setTimeout(function() {
            console.log('取消收藏');
            $('.icon-unstar').click();
            setTimeout(function() {
                console.log('确认');
                Array.from($('.modal-container .primary')).pop().click();
                setTimeout(function() {
                    console.log('稍等...');
                    batdo();
                }, 3200);
            }, 1100);
        }, 1100);  
    }, 1100);
})()
```

# 批量取消追番

收藏页 - F12控制台：

```js
(function cl() {
    let e = document.querySelector("#page-bangumi > div > div.section.bangumi > div > div > ul > li:nth-child(1) > div > ul > li:nth-child(4)");

    if (e) {
        e.click();

        setTimeout(cl, 0);
    }
})();
```


# 批量取消追剧

收藏页 - F12控制台：

```js
(function cl() {
    let e = document.querySelector("#page-pgc > div > div.section.pgc > div > div > ul > li:nth-child(1) > div > ul > li:nth-child(4)");
    if (e) {
        e.click();
        setTimeout(cl, 0);
    }
})();

```

