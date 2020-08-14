export default function(canvas,channel){
    this.events = []
    this.handle_interactions = () => {
        console.log(this.events);
        let events = this.events;
        channel.push("user_input",{
                body: JSON.stringify({user_input:events})
        })
        this.events = []
    }
    canvas.addEventListener('UIE', x => {
        this.events.push(x.detail)
    })
    function decode_mouse_buttons(bint){
        let buttons = []
        if(bint == 0){
            return []
        }
        if(bint >= 16){
            buttons.push("M5");
            bint -= 16
        }
        if(bint >= 8){
            buttons.push("M4");
            bint -= 8
        }
        if(bint >= 4){
            buttons.push("M3");
            bint -= 4
        }
        if(bint >= 2){
            buttons.push("M2");
            bint -= 2
        }
        if(bint >= 1){
            buttons.push("M1");
            bint -= 1
        }
        return buttons;
    }

    function decode_mouse_button(bint){
        if(bint == 0){
            return "M1"
        }
        if(bint == 1){
            return "M3"
        }
        if(bint == 2){
            return "M2"
        }
        if(bint == 3){
            return "M4"
        }
        if(bint == 4){
            return "M5"
        }
        return "M0"
    }
    canvas.addEventListener('mousedown', e=>{
        let buttons = [decode_mouse_button(e.button)];
        if(e.shiftKey){
            buttons.push("SHIFT")
        }
        if(e.ctrlKey){
            buttons.push("CTRL")
        }
        let event = new CustomEvent("UIE",{detail:{
            pos_x: e.offsetX,
            pos_y: e.offsetY,
            buttons: buttons,
            mouse: "DOWN"
        }})
        canvas.dispatchEvent(event);
        this.curr_time = new Date().getTime()
    })

    canvas.addEventListener('mousemove', e=>{
        this.curr_x = e.offsetX;
        this.curr_y = e.offsetY;
        let now = new Date().getTime()
        if(e.buttons && (true || now - this.curr_time > 100)){
            this.curr_time = new Date().getTime();
            let buttons = decode_mouse_buttons(e.buttons);
            if(e.shiftKey){
                buttons.push("SHIFT")
            }
            if(e.ctrlKey){
                buttons.push("CTRL")
            }
            let event = new CustomEvent("UIE",{detail:{
                pos_x: e.offsetX,
                pos_y: e.offsetY,
                buttons: buttons,
                mouse: "DRAG"
            }})
            canvas.dispatchEvent(event);
        }
    })
    canvas.addEventListener('mouseup', e=>{
        let buttons = [decode_mouse_button(e.button)];
        if(e.shiftKey){
            buttons.push("SHIFT")
        }
        if(e.ctrlKey){
            buttons.push("CTRL")
        }
        let event = new CustomEvent("UIE",{detail:{
            pos_x: e.offsetX,
            pos_y: e.offsetY,
            buttons: buttons,
            mouse: "UP"
        }})
        canvas.dispatchEvent(event);
        this.handle_interactions()
    })
    document.addEventListener('keydown', e=>{
        if(e.key == "Shift" || e.key == "Control"){
            return
        }
        if(e.repeat){
            return
        }
        let buttons = []
        buttons.push(e.key);
        if(e.shiftKey){
            buttons.push("SHIFT");
        }
        let x = this.curr_x;
        let y = this.curr_y;
        let numpad = e.location == 0x03
        let event = new CustomEvent("UIE",{detail:{
            pos_x: x,
            pos_y: y,
            buttons: buttons,
            numpad: numpad
        }})
        canvas.dispatchEvent(event)
        this.handle_interactions()
    })


}
