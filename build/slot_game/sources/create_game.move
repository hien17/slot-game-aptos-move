script {
    fun create_game(user: &signer) {
        let amount_to_play = 100;
        let items_id = 0;
        slot_game::slot_game::create_game(user, amount_to_play, items_id);
    }
}